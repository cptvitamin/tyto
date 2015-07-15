Column = require './column'

module.exports = Backbone.Marionette.CompositeView.extend
  tagName           : 'div'
  className         : 'tyto--board'
  template          : Tyto.templateStore.board
  templateHelpers   : ->
    columns: this.collection
    boards : Tyto.boardList
  childView         : Column
  childViewContainer: '.columns'
  childViewOptions: (c) ->
    colTasks = Tyto.taskList.where
      columnId: c.id
    boardView = this
    collection : new Tyto.Tasks.TaskList colTasks
    board      : boardView.model
  ui:
    addEntity     : '#add-entity'
    primaryActions: '.mdl-button--fab_flinger-container'
    addColumn     : '#add-column'
    deleteBoard   : '#delete-board'
    wipeBoard     : '#wipe-board'
    boardName     : '#board-name'
    superAdd      : '#super-add'

  collectionEvents:
    'add'   : 'updateSelector'
    'remove': 'updateSelector'
    'all'   : 'handleEvent'

  handleEvent: (e) ->
    view = this
    list = view.$el.find '.column'
    if e is 'destroy'
      Tyto.Utils.reorder view, list, 'data-col-id'

  events:
    'click @ui.addEntity'  : 'showMenu'
    'click @ui.addColumn'  : 'addColumn'
    'click @ui.deleteBoard': 'deleteBoard'
    'click @ui.wipeBoard'  : 'wipeBoard'
    'blur @ui.boardName'   : 'updateName'
    'click @ui.superAdd'   : 'superAddTask'

  cssClasses:
    VISIBLE_FAB_MENU: 'is-showing-options'

  showMenu: (e) ->
    bV  = this
    ctn = this.ui.primaryActions[0]
    btn = this.ui.addEntity[0]
    processClick = (evt) ->
      # Have to check on timeStamp because one event is a jQuery event.
      if e.timeStamp isnt evt.timeStamp
        ctn.classList.remove bV.cssClasses.VISIBLE_FAB_MENU
        ctn.IS_SHOWING_MENU = false
        document.removeEventListener 'click', processClick
    if !ctn.IS_SHOWING_MENU
      ctn.IS_SHOWING_MENU = true
      ctn.classList.add bV.cssClasses.VISIBLE_FAB_MENU
      document.addEventListener 'click', processClick

  updateSelector: ->
    yap 'whoah there has been a change....'

  initialize: ->
    board = this

  onBeforeRender: ->
    # This ensures that even after moving a column that when we add
    # something new that the ordinal property of each column is respected.
    this.collection.models = this.collection.sortBy 'ordinal'




  onShow: ->
    bV = this
    menuM  = bV.$el.find '#menumenu'
    bNameM = bV.$el.find '#board-name-menu'
    componentHandler.upgradeElement menuM[0] , 'MaterialMenu'
    if bNameM.length > 0
      componentHandler.upgradeElement bNameM[0] , 'MaterialMenu'

  onRender: ->
    bV = this
    this.bindColumns()

  bindColumns: ->
    self        = this
    this.$el.find('.columns').sortable
      connectWith: '.column',
      handle     : '.column_actions'
      handle     : '.column--mover'
      placeholder: 'column-placeholder'
      axis       : "x"
      containment: this.$el.find('.columns')
      stop       : (event, ui) ->
        list        = Array.prototype.slice.call self.$el.find '.column'
        Tyto.Utils.reorder self, list, 'data-col-id'



  addColumn: ->
    board   = this.model
    columns = this.collection
    this.$el.addClass 'is--adding-column'

    columns.add Tyto.columnList.create
      boardId: board.id
      ordinal: columns.length + 1

  updateName: ->
    this.model.save
      title: this.ui.boardName.text().trim()

  superAddTask: ->
    ###
      Need to intercept on the edit page if we use history back.
    ###

    board   = this.model

    newTask = Tyto.taskList.create
      boardId: board.id

    Tyto.navigate '#board/' + board.id + '/task/' + newTask.id, true

  deleteBoard: ->
    view = this
    if confirm 'are you sure???'
      view.wipeBoard()
      view.model.destroy()
      view.destroy()
      Tyto.navigate '/',
        trigger: true

  wipeBoard: (dontConfirm) ->
    view = this
    wipe = ->
      view.children.forEach (colView) ->
        while colView.collection.length isnt 0
          colView.collection.first().destroy()
        colView.model.destroy()
    if dontConfirm
      if confirm 'are you sure???'
        wipe()
    else
        wipe()

    return
