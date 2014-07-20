angular.module("starter-app.data", [])
angular.module("starter-app.github", [])
angular.module('fireUser').value 'FireUserConfig',
  url:"https://angular-starter-kit.firebaseio.com/"
  redirectPath:'/getting-started'
  routing:true
  routeRedirect: 'foo'
  # routeAccess: 'private'
  # (optional): this is the name of the data object you want to bind to your firebase data, and the name of the firebase data. Defaults to data
  # dataLocation:"FireUser",
  # (optional): this is where the user data should be stored within your data directory. It defaults to user.
  # userData:"data",
angular.module("starter-app", ['starter-app.github', 'ui.router', 'ui.bootstrap','firebase', 'fireUser'])
