

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
  # authorized = false
  # $httpBackend.whenPOST("auth/login").respond (method, url, data) ->
  #   authorized = true
  #   [200]

  # $httpBackend.whenPOST("auth/logout").respond (method, url, data) ->
  #   authorized = false
  #   [200]

  # $httpBackend.whenPOST("data/public/process").respond (method, url, data) ->
  #   [
  #     401
  #     "waiting and processing your data [" + data + "]."
  #   ]
  # $httpBackend.whenPOST(new RegExp("api/.*")).respond (method, url, data) ->
  #   [
  #     200
  #     "I have received and processed your data [" + data + "]."
  #   ]

  # $httpBackend.whenPOST("data/protected").respond (method, url, data) ->
  #   (if authorized then [
  #     200
  #     "This is confidential [" + data + "]."
  #   ] else [401])

  
  # # Mock out the call to '/service/hello'
  # $httpBackend.whenGET("service/hello").respond 200,
  #   message: "world"
  
  # # let all views through (the actual html views from the views folder should be loaded)
  # $httpBackend.whenGET(new RegExp("views/.*")).passThrough()
  
  # Respond with 404 for all other service calls
  # $httpBackend.whenGET(new RegExp("service/.*")).respond 404

  # #otherwise
  $httpBackend.whenGET(/.*/).passThrough()
  $httpBackend.whenPOST(/.*/).passThrough()
  return



# ///////////

angular.module("content", [])
.controller "ContentController", ($scope, $http) ->
  $scope.publicContent = []
  $scope.restrictedContent = []
  $scope.publicAction = ->
    $http.get("service/hello").success (response) ->
      $scope.publicContent.push response
    # $http.post("data/public/process", $scope.publicData).success (response) ->
    #   $scope.publicContent.push response

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
    # scope.$on "$firebaseSimpleLogin:logout", ->
    # # scope.$on "fireuser:logout", ->
    #   login.slideDown "slow", ->
    #     main.hide()
    #     return
    #   return

    scope.$on "event:auth-loginConfirmed", ->
    # scope.$on "fireuser:login", ->
    # scope.$on "$firebaseSimpleLogin:login", ->
      main.show()
      login.slideUp()
      return
    return



angular.module("starter-app", ['starter-app.github', 'ui.router', 'ui.bootstrap','firebase', 'fireUser', "angular-auth-demo", 'angularFileUpload'])

  # hack for fireUser SignUp directive to login automatically if existing
.directive "newfusignupform", [
  "$compile"
  "FireUserValues"
  ($compile, FireUserValues) ->
    return (
      scope: {}
      restrict: "E"
      controller: "newfireusersignupformCtrl"
      link: ($scope, element, attr, ctrl) ->
        element.html "<form name=\"signupForm\" ng-submit=\"createUser()\">" + "<formgroup>" + "Email <input class=\"form-control\" type=\"email\" name=\"email\" ng-model=\"email\" required/>" + "</formgroup>" + "<formgroup>" + "Password <input class=\"form-control\" type=\"password\" name=\"password\" ng-model=\"password\" required/>" + "</formgroup>" + "  <br />" + "  <button type=\"submit\" class=\"btn btn-primary pull-right\" value=\"creatUser\">Sign Up</button>" + "  <span class=\"error\" ng-show=\"error\">{{error}}</span>" + "</form>"
        $compile(element.contents()) $scope
        return
    )
]

.controller "newfireusersignupformCtrl", [
  "$scope"
  "$fireUser"
  ($scope, $fireUser) ->
    $scope.createUser = () ->
      info = { email: $scope.email, password: $scope.password }
      $fireUser.createUser(info).then (user) ->
        console.log user
      , (error) ->
        console.log error
        switch error.code
          when 'EMAIL_TAKEN' 
            console.log "Exists... now logging in now automatically"
            $fireUser.login "password", info

      return
]



.factory "Upload", ($firebase, $timeout, $http, $log, $upload, $rootScope) ->
  ref = new Firebase("https://angular-starter-kit.firebaseio.com/users/"+$rootScope.data.userInfo.id+"/uploads")
  uploads = $firebase(ref)
  files = []
  urls = []
  $rootScope.$on "fireuser:data_loaded", ->
    user = $rootScope.data.userInfo
    
    

  # $rootScope.$on '', (e, user) ->
  #   user = user
  
    
  getUrls = () ->
    if urls.length
      $log.log "do now"+urls
      sendEmail()
      urls = []

  Upload = 
    getCurrent: ->
      $rootScope.data.userInfo
    all: uploads
    notify: (url) ->
      urls.push url
      $timeout(->
        getUrls()
      ,100000)

    find: (uploadId) ->
      uploads.$child uploadId

    add: (file)->
      files.push file
      $rootScope.$broadcast 'fileAdded', file.files[0].name
    setProgress: (percentage) ->
      $rootScope.$broadcast 'uploadProgress', percentage
    create: (transloadit) ->
      user = Upload.getCurrent()
      console.log "in create, user is "+user.id
      transloadit.owner = user.id
      uploads.$add(transloadit).then (ref) ->

        uploadId = ref.name()
        # user.$child('uploads').$child(uploadId).$set uploadId
        Upload.check uploadId
        # uploadId

    update: (uploadId, transloadit) ->
      $log.log "uploadId is #{uploadId} and transloadit: #{angular.toJson transloadit}"
      # transloadit.owner = User.getCurrent().username
      uploads.$child(uploadId).$update(transloadit).then (ref) ->
        Upload.check uploadId

    list: (cb) ->
      $http.get("/api/transloadit?mimeType=" + file.type).success(cb)  

    progress: (evt) ->
      # file.progress = parseInt(100.0 * evt.loaded / evt.total)
      console.log "percent: " + parseInt(100.0 * evt.loaded / evt.total)

    upload: (file, template_id, steps, uploadId) ->
      $http.post("/api/transloadit?template_id=" + template_id, steps).success (response) ->
        paramsToTransloadit =
          url: 'http://api2.transloadit.com/assemblies'
          method: "POST"
          file: file
          data:
            params: angular.toJson response.params
            signature: response.signature
        $upload.upload(paramsToTransloadit).progress(Upload.progress).then (response) ->
        # $http(paramsToTransloadit) if uploadId?
          {data:{ok,assembly_id,assembly_url}} = response
          Upload.create {assembly_id, assembly_url, ok}
          # if uploadId
            # Upload.update uploadId,{assembly_id, assembly_url, ok}
          # else
            # Upload.create {assembly_id, assembly_url, ok}

    convert: (url, template_id, steps, uploadId) ->
      $http.post("/api/transloadit?template_id=" + template_id, steps).success (response) ->
        paramsToTransloadit =
          url: 'http://api2.transloadit.com/assemblies'
          method: "POST"
          data:
            params: angular.toJson response.params
            signature: response.signature
          # file: url
        $http(paramsToTransloadit).then ({data:{ok,assembly_id,assembly_url}}) ->
          # {data:{ok,assembly_id,assembly_url, results:{":original":[{url}]}}} = response
          if uploadId?
            Upload.update uploadId,{assembly_id, assembly_url, ok}
          if !uploadId?
            Upload.create {assembly_id, assembly_url, ok}


    get: (uploadId) ->
      upload = uploads.$child uploadId
    
    check: (uploadId) ->
      upload = uploads.$child uploadId
      $timeout(->
        $http.get(upload.assembly_url).success((transloadit) ->
          if transloadit.ok is "ASSEMBLY_COMPLETED"
            data = {}
            angular.forEach transloadit.results, (val, key) ->
              url = transloadit.results[key][0].url
              data[key] = url
              # Upload.notify url
            data.ok = transloadit.ok
            upload.$update(data)
            # upload.$save
          else
            Upload.check uploadId
          return
        )
      , 2000)



.controller "UploadCtrl", ($rootScope, $scope, $upload, $location, $timeout, $http, Upload, $log) ->
  $scope.uploads = {}
  $scope.foo = Upload
  # $rootScope.$on "theUser", ->
  #   $scope.user = $rootScope.currentUser
  #   populateUploads()
  # populateUploads = ->
  #   $scope.uploads = {}
    
  #   angular.forEach $rootScope.currentUser.uploads, (uploadId) ->
  #     $scope.uploads[uploadId] = Upload.find(uploadId)

  # $scope.gallery = Gallery
  # $scope.selectedUpload = 'none'
  # s3Store = '3ff06ee0eec011e38d300b3da55cc2f7'
        
  # imageUploadSteps = {
  #   "optimized": {
  #     "robot": "/image/optimize"
  #     "use": ":original",
  #   },
  #   "thumb": {
  #     "robot": "/image/resize",
  #     "use": ":original",
  #     "resize_strategy": "fillcrop",
  #     "strip": "true",
  #     "format": "jpg",
  #     "width": 75,
  #     "height": 75
  #   },
  #   "pdfThumb": {
  #     "robot": "/document/thumbs",
  #     "use": ":original",
  #     "trim_whitespace": false,
  #     # "density": null,
  #     "width": 75,
  #     "height": 75,
  #     "resize_strategy": "pad",
  #     "background": "#000000"
  #   },
  #   "pdf": {
  #     "robot": "/document/thumbs",
  #     "use": ":original"
  #   },
  #   "store": {
  #     "use": [":original","optimized", "thumb","pdfThumb", "pdf"],
  #     "path": "${previous_step.name}/${unique_prefix}/${file.id}.${file.ext}",
  #     "acl": "public-read"
  #   }
  # }
  $scope.selectUpload = (id) ->
    $scope.selectedUpload = $scope.uploads[id]
  
  # $scope.onFileSelect = ($files) ->
  #   $scope.files = $files
  #   $scope.upload = []
  #   $scope.percentage = 0

  #   for file in $files 
  #     Upload.upload(file, s3Store, imageUploadSteps)
  #   return
  # $scope.testUpload = (url, uploadId) ->

  $scope.crop = (uploadId, x, y, x2, y2) ->  
    upload = Upload.get uploadId 
    upload = upload.optimized ? upload.pdf
    console.log upload
    steps = {
      'imported': { #//example shows u can call ":original"
        "robot": '/http/import',
        "url": upload
      },
      "cropped": {
        "robot": "/image/resize",
        # "width": 1920,
        # "height": 600,
        crop: {
          x1: 30,
          y1: 30,
          x2: 120,
          y2: 90
        },
        resize_strategy: "crop"
      },
      "store": {
        "use": ["cropped"], # will use above by default
        "path": "${previous_step.name}/${unique_prefix}/${file.id}.${file.ext}",
        "acl": "public-read"
      }
    }
    Upload.convert(null,s3Store,steps, uploadId)  
  $scope.makeSlider = (url, uploadId) ->
    steps = {
      'imported': { #//example shows u can call ":original"
        "robot": '/http/import',
        "url": url
      },
      "files": {
        "robot": "/file/filter",
        "accepts": [
          ["${file.mime}", "regex", "image"]
        ],
        "declines": [
          ["${file.size}", ">", "20971520"],
          ["${file.meta.duration}", ">", "300"]
        ],
        "error_on_decline": true
      },
      "optimize": {
        "robot": "/image/optimize"
      },
      "slider": {
        "robot": "/image/resize",
        # "use": "imported",
        "resize_strategy": "fillcrop",
        "strip": "true",
        "format": "jpg",
        "width": 1920,
        "height": 600,
        "watermark_url": "http://transloaditkts.s3.amazonaws.com/19/6d2690dc8d11e39fdaa309f8ca44f9/990ffa3c8da7e4be32994bdd13d5e228",
        "watermark_size": "10%",
        "watermark_position": "bottom-left",
        "text": [
          {
            "text": "(c) KrisTile.com",
            "size": 18,
            "font": "Lato",
            "color": "#373737",
            "valign": "bottom",
            "align": "right",
            # "stroke_width": 1,
            # "stroke_color": "#b7b7b7"
          }
        ]
      },
      "store": {
        "use": ["slider"], # will use above by default
        "path": "${previous_step.name}/${unique_prefix}/${file.id}.${file.ext}",
        "acl": "public-read"
      }
    }
    Upload.convert(null,s3Store,steps, uploadId)
.directive "uploader", ->
  restrict: "E"
  templateUrl: "/templates/uploader.html"  
  controller: (Upload, $scope)->
    s3Store = '3ff06ee0eec011e38d300b3da55cc2f7'
    imageUploadSteps = {
      # "optimized": {
      #   "robot": "/image/optimize"
      #   "use": ":original",
      # },
      "thumb": {
        "robot": "/image/resize",
        "use": ":original",
        "resize_strategy": "fillcrop",
        "strip": "true",
        "format": "jpg",
        "width": 75,
        "height": 75
      },
      "pdfThumb": {
        "robot": "/document/thumbs",
        "use": ":original",
        "trim_whitespace": false,
        # "density": null,
        "width": 75,
        "height": 75,
        "resize_strategy": "pad",
        "background": "#000000"
      },
      "pdf": {
        "robot": "/document/thumbs",
        "use": ":original"
      },
      "store": {
        "use": [":original", "thumb","pdfThumb", "pdf"],
        "path": "${previous_step.name}/${unique_prefix}/${file.id}.${file.ext}",
        "acl": "public-read"
      }
    }

    $files = @added = {}
    @add = ($files) ->
      # @added = $files
      # @percentage = 0
      # $scope.upload = []

      for file in $files 
        console.log file
        Upload.upload(file, s3Store, imageUploadSteps)
      return
    @addUrl = (url) ->
      steps = {
        'http': { #//example shows u can call ":original"
          "robot": '/http/import',
          "url": url
        },
        "thumb": {
          "robot": "/image/resize",
          "use": "http",
          "resize_strategy": "fillcrop",
          "strip": "true",
          "format": "jpg",
          "width": 75,
          "height": 75
        },
        "store": {
          "use": ["http", "thumb"], # will use above by default
          # "path": "${previous_step.name}/${unique_prefix}/${file.id}.${file.ext}",
          "acl": "public-read"
        }
      }
      Upload.convert(null,s3Store,steps)
      $scope.url = 'http://'
    return
  controllerAs: "uploader"

.directive "uploadList", ->
  restrict: "E"
  templateUrl: "/templates/upload-list.html"
  controller: (Upload, $rootScope, $scope, waitForAuth, $state)->
    waitForAuth.then ->
      $scope.createItem = ->
        unless $scope.data.user.items
          $scope.data.user = {}
          $scope.data.user.items = []
        $scope.data.user.items.push name: "new item"
        return

      $scope.remove = (item) ->
        items = $scope.data.user.items
        i = items.length - 1

        while i >= 0
          items.splice i, 1  if items[i] is item
          i--
        return

      # $scope.$watch "data.userLoggedIn", (newVal, oldval) ->
      #   userInfo = $scope.data.userInfo
      #   unless newVal
      #     $state.go "login"
      #   else
      #     if userInfo.provider is "password"
      #       $scope.loginstatus = "User " + $scope.data.userInfo.email + " logged in"
      #     else
      #       $scope.loginstatus = "User " + $scope.data.userInfo.username + " logged in"
      #   return
      return
    return





    # all = @all
    # user = $rootScope.currentUser
    # $rootScope.$on "theUser", (event, user) ->
    #   populate()
    # populate = ->
    #   angular.forEach $rootScope.currentUser.uploads, (uploadId) ->
    #     all[uploadId] = Upload.find(uploadId)
    # if user
    #   populate()
    return

  controllerAs: "uploads"
