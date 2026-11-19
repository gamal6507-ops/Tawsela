// Explicit release check against this app's dedicated Firebase project only.
// Creates a synthetic account/profile and removes both; sends no email.
const {randomUUID} = require('node:crypto');
const {initializeApp,deleteApp} = require('firebase/app');
const {getAuth,createUserWithEmailAndPassword,signOut,signInWithEmailAndPassword,deleteUser} = require('firebase/auth');
const {getFirestore,doc,setDoc,getDoc,deleteDoc,serverTimestamp,terminate} = require('firebase/firestore');
const config = {apiKey:'AIzaSyB1AoiZbF1XnkYxXOc_ayZfH4QWbrrnHA0',projectId:'tawsela-gamal6507',appId:'1:816331397345:web:38fa0c1a29122886163fa0',authDomain:'tawsela-gamal6507.firebaseapp.com'};
(async()=>{
  const app=initializeApp(config,'release-smoke');const auth=getAuth(app);const db=getFirestore(app);
  const email=`release-check-${randomUUID()}@example.com`;const password=`Qa-${randomUUID()}!`;
  let ref;let user;
  try{
    user=(await createUserWithEmailAndPassword(auth,email,password)).user;
    ref=doc(db,'users',user.uid);
    await setDoc(ref,{name:'Release verification',phone:'',email,createdAt:serverTimestamp()});
    if(!(await getDoc(ref)).exists())throw Error('Profile was not persisted');
    await signOut(auth);
    user=(await signInWithEmailAndPassword(auth,email,password)).user;
    await deleteDoc(ref);ref=null;
    await deleteUser(user);user=null;
    console.log('PASS: Firebase signup, profile persistence, sign-out/sign-in; synthetic identity and profile removed.');
  } finally {
    if(ref && auth.currentUser) await deleteDoc(ref).catch(()=>{});
    if(user && auth.currentUser) await deleteUser(auth.currentUser).catch(()=>{});
    await terminate(db);await deleteApp(app);
  }
})().catch(error=>{console.error('FAIL:',error.code || error.message);process.exitCode=1;});
