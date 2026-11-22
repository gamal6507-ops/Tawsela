# توصيلة — Tawsela

**Flutter ride-booking application for Egypt**, with distinct rider and driver experiences, Firebase-backed authentication and data, maps, booking flow, ride history, and English/Arabic interface support.

**Explore:** [Live web demo](https://tawsela-kappa.vercel.app/) · [Screenshots in my portfolio](https://ahmed-gamal-portfolio-alpha.vercel.app/#work)

> **Demo note:** Some flows require sign-in. Rides use cash on arrival; map distance/routes are approximate, and driver approval is a manual operational step. Do not place real ride requests merely to review the demo.

**Core technologies:** Flutter, Dart, Firebase/Firestore, OpenStreetMap, Vercel.

---


تطبيق Flutter عربي لحجز رحلات داخل مصر مع واجهة سائق. هذه النسخة تستخدم **الدفع كاش عند الوصول**؛ لا توجد محفظة وهمية أو شحن أو بطاقات أو خصومات مفعّلة.

## التشغيل

يتطلب Flutter 3.50.0 وDart المرفق معه. إعدادات Firebase العامة في المستودع ليست مفاتيح إدارية.

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
```

حدد النقطتين على الخريطة. البحث النصي في Vercel يستخدم `/api/geocode`؛ محليًا دون Vercel تظل الخريطة متاحة. المسافة والخط المعروض **تقريبيان بخط مباشر** وليسا مسار طريق. الأجرة تتبع معادلة ثابتة وتصبح متفقًا عليها عند قبول السائق؛ لا يوجد وعد بوقت وصول أو خصم إلكتروني.

## دورة الرحلة

1. الراكب ينشئ طلبًا واحدًا نشطًا لحسابه، حتى عند استخدام جهازين.
2. سائق معتمد ومتوفّر من نوع المركبة المطلوب يقبل الطلب. القبول وحجز السائق عملية ذرية.
3. السائق يبدأ الرحلة ويؤكد الوصول. الوصول يحفظ إيصالًا ثابتًا برقم الطلب ويحرر السائق في نفس العملية.
4. الراكب يقيّم أو يتخطى التقييم ويؤكد انتهاء الرحلة. السجل محفوظ حتى إن أغلق التطبيق قبل التأكيد.
5. المحادثة لطرفي الرحلة فقط. مشاركة موقع السائق اختيارية أثناء فتح شاشته وتتوقف عند مغادرتها، وليست تتبعًا بالخلفية.

## اعتماد السائقين

افتح **مساحة السائق** من حساب السائق وأرسل الاسم والموبايل واللوحة ونوع المركبة. الطلب يبدأ بـ `approved: false` دون صلاحية استقبال طلبات.

مسؤول المشروع يراجع الهوية ورخصة القيادة والمركبة **خارج التطبيق**، ثم يغير `drivers/{uid}.approved` إلى `true` في [Firestore](https://console.firebase.google.com/project/tawsela-gamal6507/firestore). لا تعتمد سائقًا دون مراجعة حقيقية. المستخدم لا يستطيع منح نفسه الاعتماد. الاعتماد وإلغاؤه يدويان؛ لا يوجد تحقق آلي من المستندات.

## Firebase

- المشروع `tawsela-gamal6507`، منفصل عن مشروع الإعدادات القديمة غير المتاح للحساب المتصل.
- Firestore Standard، قاعدة `(default)`، موقع `nam5`، الباقة المجانية.
- الإيميل وكلمة السر مفعّلان. القواعد والفهارس في `firestore.rules` و`firestore.indexes.json`.
- الإشعارات صندوق داخل التطبيق لآخر ٣٠ طلبًا وليست Push notifications.
- سجل الرحلات يعرض آخر ١٠٠ رحلة كحد أقصى، دون بيانات نموذجية في الإنتاج.

```sh
npx firebase-tools deploy --only firestore,auth --project tawsela-gamal6507
```

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for authenticated ownership, approved drivers, immutable cash fares, and atomic ride transitions. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

قواعد الصلاحيات مبدئية ومرفق معها اختبارات محاكي. تحتاج مراجعة تشغيلية وأمنية قبل التوسع العام؛ إخفاء أزرار الواجهة ليس وسيلة الحماية.

## التحقق

اختبار القواعد يتطلب Node.js 22+ وJava 21 ويستخدم مشروع `demo-tawsela` المعزول على المنفذ `8188`، دون بيانات الإنتاج.

```sh
flutter analyze --no-fatal-infos
flutter test
npm ci
npm test
npm run test:rules
flutter build web --release --no-web-resources-cdn
```

`--no-fatal-infos` يسمح بإشعارات إهمال استيراد Material في Flutter 3.50؛ الأخطاء والتحذيرات تظل سببًا للفشل. CI يشغّل الاختبارات والتحليل وبناء الويب على كل Push وPull Request.

## النشر والخدمات المجانية

`vercel.json` يبني `build/web` مع دالة Node للبحث وإعادة كتابة مسارات الصفحات دون اعتراض API أو الأصول. `scripts/build-web.sh` يثبت إصدار Flutter. لا تحتاج أسرار Firebase إدارية في Vercel.

الخرائط من OpenStreetMap مع الإسناد المطلوب. البحث اليدوي منخفض الاستخدام يستخدم Photon العام، مع تخزين مؤقت وتقليل طلبات في كل نسخة خادم؛ ليس حدًا عالميًا موزعًا أو ضمان توافر. غيّر المزود من متغير `GEOCODING_ORIGIN` عند الحاجة. الاختيار من الخريطة يظل متاحًا إذا تعطل البحث. لا تفعّل بحثًا جماعيًا أو إكمالًا تلقائيًا على المزود العام.

الباقات المجانية لها حصص وشروط استخدام. لم تُفعّل خدمات مدفوعة أو بطاقة بنكية. التشغيل التجاري والتوسع يحتاجان مراجعة حصص وشروط Vercel وFirebase ومزود الخرائط.

## الحساب والخصوصية

تغيير إيميل تسجيل الدخول من شاشة الأمان يتطلب كلمة السر والتأكيد من الإيميل الجديد. إيميل الملف الشخصي للعرض فقط. حذف الحساب يتطلب إعادة تحقق وعدم وجود رحلة نشطة، ويحذف الملف الشخصي وطلب السائق وعلامات الإشعارات. سجلات الرحلات والمحادثات والتقييمات لا تُحذف تلقائيًا كما توضح الشاشة؛ سياسة الاحتفاظ وطلبات حذفها مسؤولية المشغّل قبل الإطلاق التجاري.

Google Sign-In جاهز جزئيًا في الكود لكنه مخفي ومعطل في الإصدار. قبل البناء بـ `GOOGLE_SIGN_IN_ENABLED=true` يلزم تفعيل المزود والنطاق المعتمد وOAuth وSHA الخاص بـAndroid ومخطط URL لـiOS، وإضافة إعادة تحقق Google في شاشة الأمان. لا تفعل حسابات Google فقط قبل استكمال ذلك.

## حدود الإصدار

لا يوجد اعتماد هوية آلي، تأمين رحلات، دعم فوري، خدمة طوارئ، دفع إلكتروني، أو أسطول سائقين جاهز. Android يحتاج توقيع إصدار يملكه المشغّل؛ أُزيل توقيع Debug من Release. إصدارات المتاجر وmacOS/Windows غير مختبرة، والهدف الحالي الويب. لا ترسل بيانات شخصية أو أسرارًا في [بلاغات GitHub العامة](https://github.com/gamal6507-ops/Tawsela/issues).

---

## Developer & contact

**Ahmed Gamal Saeed** — Software Developer focused on Flutter and modern web applications.

- [Portfolio — selected projects and demos](https://ahmed-gamal-portfolio-alpha.vercel.app/)
- [LinkedIn — professional profile](https://www.linkedin.com/in/ahmed-gamal-717b54450/)
- [GitHub — source code](https://github.com/gamal6507-ops)

