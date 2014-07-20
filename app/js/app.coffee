

#global angular:true, browser:true 

###
@license HTTP Auth Interceptor Module for AngularJS
(c) 2012 Witold Szczerba
License: MIT
###

###
Call this function to indicate that authentication was successfull and trigger a
retry of all deferred requests.
@param data an optional argument to pass on to $broadcast which may be useful for
example if you need to pass through details of the user that was logged in
###

###
Call this function to indicate that authentication should not proceed.
All deferred requests will be abandoned or rejected (if reason is provided).
@param data an optional argument to pass on to $broadcast.
@param reason if provided, the requests are rejected; abandoned otherwise.
###

###
$http interceptor.
On 401 response (without 'ignoreAuthModule' option) stores the request
and broadcasts 'event:auth-loginRequired'.
###
angular.module("http-auth-interceptor", ["http-auth-interceptor-buffer"]).factory("authService", [
  "$rootScope"
  "httpBuffer"
  ($rootScope, httpBuffer) ->
    return (
      loginConfirmed: (data, configUpdater) ->
        updater = configUpdater or (config) ->
          config

        $rootScope.$broadcast "event:auth-loginConfirmed", data
        httpBuffer.retryAll updater
        return

      loginCancelled: (data, reason) ->
        httpBuffer.rejectAll reason
        $rootScope.$broadcast "event:auth-loginCancelled", data
        return
    )
]).config [
  "$httpProvider"
  ($httpProvider) ->
    $httpProvider.interceptors.push [
      "$rootScope"
      "$q"
      "httpBuffer"
      ($rootScope, $q, httpBuffer) ->
        return responseError: (rejection) ->
          if rejection.status is 401 and not rejection.config.ignoreAuthModule
            deferred = $q.defer()
            httpBuffer.append rejection.config, deferred
            $rootScope.$broadcast "event:auth-loginRequired", rejection
            return deferred.promise
          
          # otherwise, default behaviour
          $q.reject rejection
    ]
]

###
Private module, a utility, required internally by 'http-auth-interceptor'.
###
angular.module("http-auth-interceptor-buffer", []).factory "httpBuffer", [
  "$injector"
  ($injector) ->
    
    ###
    Holds all the requests, so they can be re-requested in future.
    ###
    
    ###
    Service initialized later because of circular dependency problem.
    ###
    retryHttpRequest = (config, deferred) ->
      successCallback = (response) ->
        deferred.resolve response
        return
      errorCallback = (response) ->
        deferred.reject response
        return
      $http = $http or $injector.get("$http")
      $http(config).then successCallback, errorCallback
      return
    buffer = []
    $http = undefined
    return (
      
      ###
      Appends HTTP request configuration object with deferred response attached to buffer.
      ###
      append: (config, deferred) ->
        buffer.push
          config: config
          deferred: deferred

        return

      
      ###
      Abandon or reject (if reason provided) all the buffered requests.
      ###
      rejectAll: (reason) ->
        if reason
          i = 0

          while i < buffer.length
            buffer[i].deferred.reject reason
            ++i
        buffer = []
        return

      
      ###
      Retries all the buffered requests clears the buffer.
      ###
      retryAll: (updater) ->
        i = 0

        while i < buffer.length
          retryHttpRequest updater(buffer[i].config), buffer[i].deferred
          ++i
        buffer = []
        return
    )
]




angular.module("starter-app.data", [])
angular.module("starter-app.github", [])
angular.module('fireUser').value 'FireUserConfig',
  url:"https://angular-starter-kit.firebaseio.com/"
  redirectPath:'foo'
  routing:true
  # routeRedirect: 'foo' # path to redirect if user not authenticated. 'login' is default
  # routeAccess: 'private'
  # (optional): this is the name of the data object you want to bind to your firebase data, and the name of the firebase data. Defaults to data
  # dataLocation:"FireUser",
  # (optional): this is where the user data should be stored within your data directory. It defaults to user.
  # userData:"data",


###
This module is used to simulate backend server for this demo application.
###
angular.module("content-mocks", ["ngMockE2E"])
.run ($httpBackend) ->
  authorized = false
  $httpBackend.whenPOST("auth/login").respond (method, url, data) ->
    authorized = true
    [200]

  $httpBackend.whenPOST("auth/logout").respond (method, url, data) ->
    authorized = false
    [200]

  $httpBackend.whenPOST("data/public").respond (method, url, data) ->
    [
      200
      "I have received and processed your data [" + data + "]."
    ]

  $httpBackend.whenPOST("data/protected").respond (method, url, data) ->
    (if authorized then [
      200
      "This is confidential [" + data + "]."
    ] else [401])

  
  #otherwise
  $httpBackend.whenGET(/.*/).passThrough()
  return


# ///////////

angular.module("content", [])
.controller "ContentController", ($scope, $http) ->
  $scope.publicContent = []
  $scope.restrictedContent = []
  $scope.publicAction = ->
    $http.post("data/public", $scope.publicData).success (response) ->
      $scope.publicContent.push response

  $scope.restrictedAction = ->
    $http.post("data/protected", $scope.restrictedData).success (response) ->      
      # this piece of code will not be executed until user is authenticated
      $scope.restrictedContent.push response

  $scope.logout = ->
    $http.post("auth/logout").success ->
      $scope.restrictedContent = []
      return


# /////////////login.js
angular.module("login", ["http-auth-interceptor", 'fireUser', 'firebase'])
.controller "LoginController", ($scope, $http, authService) ->
  $scope.submit = ->
    $http.post("auth/login").success ->
      authService.loginConfirmed()
      return

# ////// main.js

###
This directive will find itself inside HTML as a class,
and will remove that class, so CSS will remove loading image and show app content.
It is also responsible for showing/hiding login form.
###
angular.module("angular-auth-demo", [
  "http-auth-interceptor"
  "content-mocks"
  "login"
  "content"
])

.directive "authDemoApplication", ->
  restrict: "C"
  link: (scope, elem, attrs) ->
    
    #once Angular is started, remove class:
    elem.removeClass "waiting-for-angular"
    login = elem.find("#login-holder")
    main = elem.find("#content")
    login.hide()
    scope.$on "event:auth-loginRequired", ->
      login.slideDown "slow", ->
        main.hide()
        return
      return
    scope.$on "fireuser:logout", ->
      login.slideDown "slow", ->
        main.hide()
        return
      return

    # scope.$on "event:auth-loginConfirmed", ->
    scope.$on "fireuser:login", ->
      main.show()
      login.slideUp()
      return
    return



angular.module("starter-app", ['starter-app.github', 'ui.router', 'ui.bootstrap','firebase', 'fireUser', "angular-auth-demo"])

