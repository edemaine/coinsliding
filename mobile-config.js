// meteor build ..\build --server=https://coinsliding.erikdemaine.org/
// cd ..\build\android\project\build\outputs\apk\release
// jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 android-release-unsigned.apk coinsliding
// zipalign -f 4 android-release-unsigned.apk coinsliding.apk

App.info({
  id: 'org.erikdemaine.coinsliding',
  name: 'Coin Sliding',
  version: '1.0.3',
  author: 'Erik Demaine',
  email: 'edemaine+coinsliding@mit.edu'
});

App.accessRule('*');
App.accessRule('blob:*');
