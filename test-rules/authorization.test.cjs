const {test, before, after, beforeEach} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,collection,query,where,getDocs} = require('firebase/firestore');
let env;
const rider = () => env.authenticatedContext('rider').firestore();
const captain = () => env.authenticatedContext('captain').firestore();
const other = () => env.authenticatedContext('other').firestore();
const guest = () => env.unauthenticatedContext().firestore();
const base = () => ({userId:'rider',userName:'Rider',from:'A',to:'B',pickupLat:30,pickupLng:31,dropoffLat:30.02,dropoffLng:31.015,
  rideType:'car',distanceKm:2.7,price:21,paymentMethod:'cash',status:'searching',createdAt:serverTimestamp()});
const driver = () => ({name:'Captain',phone:'01000000000',plateNumber:'ABC123',vehicleType:'car',approved:true,isAvailable:true,activeRideId:null,rating:0});
const profile = () => ({name:'Rider',phone:'01000000000',email:'rider@example.test',createdAt:serverTimestamp()});
async function seedDriver() { await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'drivers/captain'), driver())); }
async function createRide(db = rider(), overrides = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db,'ride_requests/ride1'), {...base(),...overrides});
  batch.set(doc(db,'active_rides/rider'), {requestId:'ride1'});
  return batch.commit();
}
async function accept() {
  const db = captain(); const batch = writeBatch(db);
  batch.update(doc(db,'ride_requests/ride1'), {status:'accepted',driverId:'captain',
    driver:{id:'captain',name:'Captain',phone:'01000000000',plateNumber:'ABC123',rating:0,avatarUrl:null},acceptedAt:serverTimestamp()});
  batch.update(doc(db,'drivers/captain'), {isAvailable:false,activeRideId:'ride1'});
  return batch.commit();
}
before(async () => { env = await initializeTestEnvironment({projectId:'demo-tawsela',firestore:{rules:readFileSync('firestore.rules','utf8'),host:'127.0.0.1',port:8188}}); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
test('cash fare calculation and atomic own booking are allowed', async () => { await assertSucceeds(createRide()); });
test('guest cannot create a booking', async () => { await assertFails(createRide(guest())); });
test('another user cannot create a rider booking', async () => { await assertFails(createRide(other())); });
test('tampered price is rejected', async () => { await assertFails(createRide(rider(),{price:1})); });
test('tampered distance is rejected', async () => { await assertFails(createRide(rider(),{distanceKm:1,price:14})); });
test('electronic payment is rejected', async () => { await assertFails(createRide(rider(),{paymentMethod:'wallet'})); });
test('out of region coordinate is rejected', async () => { await assertFails(createRide(rider(),{pickupLat:40})); });
test('creating a request without the active pointer is rejected', async () => { const db=rider(); await assertFails(setDoc(doc(db,'ride_requests/ride1'),base())); });
test('user profile requires validated fields on create and update', async () => {
  const db=rider(); await assertSucceeds(setDoc(doc(db,'users/rider'),profile()));
  await assertFails(updateDoc(doc(db,'users/rider'),{name:3}));
  await assertFails(updateDoc(doc(db,'users/rider'),{approved:true}));
  await assertFails(getDoc(doc(other(),'users/rider')));
});
test('rider cannot accept or start their own ride', async () => {
  await createRide(); await assertFails(updateDoc(doc(rider(),'ride_requests/ride1'),{status:'accepted'}));
  await assertFails(updateDoc(doc(rider(),'ride_requests/ride1'),{status:'in_progress',startedAt:serverTimestamp()}));
});
test('driver registration cannot grant its own approval', async () => {
  const db=captain(); await assertFails(setDoc(doc(db,'drivers/captain'),driver()));
  await assertSucceeds(setDoc(doc(db,'drivers/captain'),{...driver(),approved:false,isAvailable:false}));
  await assertFails(updateDoc(doc(db,'drivers/captain'),{approved:true}));
});
test('unapproved driver cannot browse rider requests', async () => {
  await createRide(); await assertFails(getDocs(query(collection(captain(),'ride_requests'),where('status','==','searching'),where('rideType','==','car'))));
});
test('approved available driver may query matching searching requests', async () => {
  await createRide(); await seedDriver();
  await assertSucceeds(getDocs(query(collection(captain(),'ride_requests'),where('status','==','searching'),where('rideType','==','car'))));
});
test('acceptance atomically reserves approved driver', async () => { await createRide(); await seedDriver(); await assertSucceeds(accept()); });
test('acceptance without reserving driver is rejected', async () => {
  await createRide(); await seedDriver(); const db=captain();
  await assertFails(updateDoc(doc(db,'ride_requests/ride1'),{status:'accepted',driverId:'captain',driver:{id:'captain',name:'Captain',phone:'01000000000',plateNumber:'ABC123',rating:0,avatarUrl:null},acceptedAt:serverTimestamp()}));
});
test('other users cannot read or change a ride', async () => {
  await createRide(); await assertFails(getDoc(doc(other(),'ride_requests/ride1')));
  await assertFails(updateDoc(doc(other(),'ride_requests/ride1'),{status:'cancelled'}));
});
test('cancellation is atomic and cancelled request cannot become accepted', async () => {
  await createRide(); await seedDriver(); const db=rider(); const batch=writeBatch(db);
  batch.update(doc(db,'ride_requests/ride1'),{status:'cancelled',updatedAt:serverTimestamp()}); batch.delete(doc(db,'active_rides/rider'));
  await assertSucceeds(batch.commit()); await assertFails(accept());
});
test('accepted cancellation releases the driver and active pointer', async () => {
  await createRide(); await seedDriver(); await accept(); const db=rider(); const batch=writeBatch(db);
  batch.update(doc(db,'ride_requests/ride1'),{status:'cancelled',updatedAt:serverTimestamp()});
  batch.update(doc(db,'drivers/captain'),{isAvailable:true,activeRideId:null}); batch.delete(doc(db,'active_rides/rider'));
  await assertSucceeds(batch.commit());
});
test('full driver lifecycle writes a single immutable receipt, then rider acknowledges', async () => {
  await createRide(); await seedDriver(); await accept(); const db=captain();
  await assertSucceeds(updateDoc(doc(db,'ride_requests/ride1'),{status:'in_progress',startedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(rider(),'ride_requests/ride1'),{status:'arrived'}));
  const batch=writeBatch(db);
  batch.update(doc(db,'ride_requests/ride1'),{status:'arrived',arrivedAt:serverTimestamp(),durationMinutes:5});
  batch.update(doc(db,'drivers/captain'),{isAvailable:true,activeRideId:null});
  batch.set(doc(db,'trips/ride1'),{userId:'rider',driverId:'captain',requestId:'ride1',from:'A',to:'B',rideType:'car',price:21,
    driverName:'Captain',driverRating:0,driverPlate:'ABC123',date:Date.now(),durationMinutes:5,distanceKm:2.7,paymentMethod:'cash',createdAt:serverTimestamp()});
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(doc(rider(),'trips/ride1'),{price:0}));
  await assertFails(getDoc(doc(other(),'trips/ride1')));
  await assertSucceeds(getDoc(doc(rider(),'trips/ride1')));
  const riderDb = rider();
  const ack=writeBatch(riderDb); ack.update(doc(riderDb,'ride_requests/ride1'),{status:'completed',completedAt:serverTimestamp()}); ack.delete(doc(riderDb,'active_rides/rider'));
  await assertSucceeds(ack.commit());
  const rating={userId:'rider',tripId:'ride1',stars:5,tags:['أمان'],comment:'Good',updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(rider(),'ratings/ride1'),rating));
  await assertFails(setDoc(doc(other(),'ratings/ride1'),{...rating,userId:'other'}));
  await assertFails(setDoc(doc(rider(),'ratings/ride1'),{...rating,stars:6}));
});
test('chat messages require an accepted participant and cannot spoof sender', async () => {
  await createRide(); await seedDriver(); await accept();
  const message={senderId:'rider',text:'Hello',sentAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(rider(),'ride_requests/ride1/messages/msg1'),message));
  await assertFails(setDoc(doc(other(),'ride_requests/ride1/messages/msg2'),{...message,senderId:'other'}));
  await assertFails(setDoc(doc(rider(),'ride_requests/ride1/messages/msg3'),{...message,senderId:'captain'}));
});

