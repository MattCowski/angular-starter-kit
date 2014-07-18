angular.module("starter-app.data", [])
angular.module("starter-app.github", [])
angular.module('fireUser').value 'FireUserConfig',
  url:"https://angular-starter-kit.firebaseio.com/"
  redirectPath:'/login',
  # datalocation:"FireUser",
  # userdata:"data",
  routing:true
angular.module("starter-app", ['starter-app.github', 'ui.router', 'ui.bootstrap','firebase', 'fireUser'])
