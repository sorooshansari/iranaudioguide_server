angular.module('app.routes', [])

.config(function ($stateProvider, $urlRouterProvider) {

    // Each state's controller can be found in controllers.js
    $stateProvider
    .state('primaryPage', {
        url: '/primary',
        templateUrl: 'templates/primaryPage.html',
        controller: 'primaryPageCtrl'
    })
    .state('firstPage', {
        url: '/first',
        templateUrl: 'templates/firstPage.html',
        controller: 'firstPageCtrl'
    })

    .state('secondPage', {
        url: '/second ',
        templateUrl: 'templates/secondPage.html',
        controller: 'secondPageCtrl'
    })
    .state('login', {
        url: '/login',
        templateUrl: 'templates/login.html',
        controller: 'loginCtrl'
    })

    .state('signup', {
        url: '/signup',
        templateUrl: 'templates/signup.html',
        controller: 'signupCtrl'
    })
    .state('recoverPassword', {
        url: '/recoverPass',
        templateUrl: 'templates/recoverPassword.html',
        controller: 'recoverPasswordCtrl'
    })
    .state('packages', {
        url: '/packages',
        templateUrl: 'templates/packages.html',
        controller: 'packagesCtrl'
    })
    .state('tabsController', {
        url: '/page1',
        templateUrl: 'templates/tabsController.html',
        abstract: true
    })

    .state('tabsController.home', {
        url: '/page2',
        views: {
            'tab1': {
                templateUrl: 'templates/home.html',
                controller: 'homeCtrl'
            }
        }
    })

    .state('tabsController.favorits', {
        url: '/page3',
        views: {
            'tab2': {
                templateUrl: 'templates/favorits.html',
                controller: 'favoritsCtrl'
            }
        }
    })

    .state('tabsController.search', {
        url: '/page4',
        views: {
            'tab3': {
                templateUrl: 'templates/search.html',
                controller: 'searchCtrl'
            }
        }
    })

    .state('tabsController.place', {
        url: '/page5',
        params: {
            id: 'salam'
        },
        views: {
            'tab1': {
                templateUrl: 'templates/place.html',
                controller: 'placeCtrl'
            }
        }
    })
    .state('tabsController.placeBookmarked', {
        url: '/placeBookmarked',
        params: {
            id: 'salam'
        },
        views: {
            'tab2': {
                templateUrl: 'templates/place.html',
                controller: 'placeCtrl'
            }
        }
    })
    .state('tabsController.placeSearched', {
        url: '/placeSearched',
        params: {
            id: 'salam'
        },
        views: {
            'tab3': {
                templateUrl: 'templates/place.html',
                controller: 'placeCtrl'
            }
        }
    })

    $urlRouterProvider.otherwise('/primary')
});