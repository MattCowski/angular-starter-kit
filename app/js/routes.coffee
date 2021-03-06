app = angular.module('starter-app')

app.config(($stateProvider, $urlRouterProvider) ->

  $urlRouterProvider.otherwise("/")

  $stateProvider
    .state('home', {
      url: "/",
      templateUrl: "/templates/home.html"
    })
    .state('info', {
      url: "",
      abstract: true,
      template: "<div class='info-page' data-ui-view></div>"
    })
    .state('info.features', {
      url: "/features"
      templateUrl: "/templates/features.html"
    })
    .state('info.package-management', {
      url: "/package-management"
      templateUrl: "/templates/package-management.html"
    })
    .state('info.included-libraries', {
      url: "/included-libraries"
      templateUrl: "/templates/included-libraries.html"
    })
    .state('info.project-structure', {
      url: "/project-structure"
      templateUrl: "/templates/project-structure.html"
    })
    .state('info.build-system', {
      url: "/build-system"
      templateUrl: "/templates/build-system.html"
    })
    .state('info.dev-server', {
      url: "/dev-server"
      templateUrl: "/templates/dev-server.html"
    })
    .state('info.testing', {
      url: "/testing"
      private: true
      templateUrl: "/templates/testing.html"
    })
    .state('info.getting-started', {
      url: "/getting-started",
      # private: true
      templateUrl: "/templates/getting-started.html"
    })
    .state('login', {
      url: "/login",
      # private: false
      templateUrl: "/templates/login.html",
      controller: ($firebase, $firebaseSimpleLogin, $location, $state, $rootScope) ->
        ref = new Firebase("https://angular-starter-kit.firebaseio.com/")
        $rootScope.$on "$firebaseSimpleLogin:login", ->
          console.log "doing sync"
          $state.go('home');
          # $location.path '/'
          # $scope.loginObj = Auth.loginObj
          # if Auth.signedIn()
          #   $location.path "/"
        return $firebaseSimpleLogin ref
      controllerAs: 'Auth'
    })
    .state('uploads', {
      url: "/uploads"
      private:true
      templateUrl: "/templates/uploads.html",
      controller: 'UploadCtrl'
    })
    .state('posts', {
      url: "/posts"
      private:true
      templateUrl: "/templates/posts.html",
      controller: ($firebase, $rootScope) ->
    #     newEmail = 
    #       from: ''
    #       to: ''
    #       subject: 'hi'
    #       body: 'hey there'
        ref = new Firebase("https://angular-starter-kit.firebaseio.com/users/"+$rootScope.data.userInfo.id+"/posts")
        return $firebase ref
      controllerAs: 'Posts'
    })
    .state('profile', {
      url: "/profile",
      templateUrl: "/templates/profile.html",
      private:true
    })
    .state('info.sample-code', {
      url: "/sample-code",
      templateUrl: "/templates/sample-code.html"
    })
    .state('auth', {
      url: "/auth",
      templateUrl: "/templates/auth.html"
    })
)
