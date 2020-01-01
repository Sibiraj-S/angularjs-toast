'use strict'

$toastProvider = ->
  defaultOptions =
    container: 'body'
    duration: 5 * 1000
    dismissible: true
    maxToast: 7
    position: 'right'
    containerClass: ''
    defaultToastClass: 'alert-success'
    insertFromTop: true

  options = defaultOptions

  configure: (c) ->
    options = Object.assign {}, defaultOptions, c
    return

  $get: ->
    return options

$toastFactory = ($rootScope, $http, $templateCache, $compile, $timeout, $toast) ->
  # template
  templateBase = './angularjs-toast.html'

  html = '<div class="angularjs-toast" ng-class="$toastPlace ? \'position-fixed\' : \'position-relative\'">' +
  '  <ul class="toast-container" ng-class="::[$position, $containerClass]">' +
  '    <li class="animate-repeat" ng-repeat="data in $toastMessages track by data.id">' +
  '      <div class="alert alert-dismissible" ng-class="::$toastClass">'  +
  '        <span ng-bind-html="data.message"></span>' +
  '        <a' +
  '          href="javascript:void(0)"' +
  '          class="close"' +
  '          data-dismiss="alert"' +
  '          aria-label="close"'+
  '          title="close"' +
  '          ng-click="$close($index, data.id)"'+
  '          ng-if="data.dismissible"' +
  '          >×</a' +
  '        >' +
  '      </div>' +
  '    </li>' +
  '  </ul>' +
  '</div>'

  # put html into template cache
  $templateCache.put(templateBase, html)

  # default options
  options = $toast

  # scope defaults
  scope = $rootScope.$new()
  scope.$toastMessages = []
  scope.$containerClass = options.containerClass

  timeoutPromises = {}

  cleanupToastContainer = ->
    if scope.$toastMessages.length is 0
      angular.element(document.querySelector('.angularjs-toast')).remove()

  # toast function
  toast = (args) ->

    if not args.message
      throw new Error "Toast message is required..."

    # user parameters
    args.duration = args.duration or options.duration
    args.dismissible = if args.dismissible isnt undefined then args.dismissible else options.dismissible

    # values that bind to HTML
    scope.$position = args.position or options.position
    scope.$toastPlace = if options.container is 'body' then true else false
    scope.$toastClass = args.className or options.defaultToastClass

    # check if templates are present in the body
    # append to body
    htmlTemplate = angular.element(document.getElementsByClassName 'angularjs-toast')

    if not htmlTemplate[0]
      # if the element is not appened to html
      # get default template from ->templateBase
      # append to ->options.container
      $http.get templateBase, {cache: $templateCache}
        .then (response) ->

          # compile the element
          # append default template to the ->templateBase
          templateElement = $compile(response.data)(scope)

          if angular.isElement options.container
            el = options.container
          else
            el = document.querySelector(options.container)

          angular.element(el).append templateElement
          return

    # remove element besed on time interval ->args.duration
    timeout = (msgObj) ->
      timeoutPromises[msgObj.id] = $timeout ->
        index = scope.$toastMessages.indexOf(msgObj)
        if index isnt -1
          scope.$toastMessages.splice(index, 1)

        cleanupToastContainer()
        return
      , args.duration
      return

    # append inputs to json variable
    # this will be pushed to the ->scope.$toastMessages array
    json =
      dismissible: args.dismissible
      message: args.message
      id: "#{new Date().getUTCMilliseconds()}-#{Math.floor((Math.random() * 100) + 1)}"

    # push elements to array
    pushToArray = ->
      if options.insertFromTop then scope.$toastMessages.unshift(json) else scope.$toastMessages.push(json)
      timeout(json)
      return

    # close selected element
    # remove ->$index element from ->scope.toastMessages
    scope.$close = (index, id) ->
      $timeout.cancel timeoutPromises[id]
      delete timeoutPromises[id]
      scope.$toastMessages.splice(index, 1)
      cleanupToastContainer()
      return

    # remove last/ first element from ->scope.$toastMessages when the maxlength is reached
    if scope.$toastMessages.length is options.maxToast
      if not options.insertFromTop then scope.$toastMessages.shift() else scope.$toastMessages.pop()
      pushToArray()
    else
      pushToArray()

    return

$toastFactory.$inject = ['$rootScope', '$http', '$templateCache', '$compile', '$timeout', '$toast']

angular.module 'angularjsToast', ['ngSanitize', 'ngAnimate']
  .provider '$toast', $toastProvider
  .factory 'toast', $toastFactory
