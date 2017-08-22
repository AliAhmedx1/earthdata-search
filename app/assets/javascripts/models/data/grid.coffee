ns = @edsc.models.data

ns.GridCondition = do (ko, KnockoutModel=@edsc.models.KnockoutModel) ->

  class GridAxis
    constructor: (@label, @min, @max) ->

  class Grid
    constructor: (@name, @label, @axis0, @axis1) ->

  config = [
    ['CALIPSO',         'CALIPSO',             'orbit', 1, 75000, 'path',  1, 233],
    ['MISR',            'MISR',                'path',  1,   233, 'block', 1, 180],
    ['MODIS Tile EASE', 'MODIS EASE Grid',     'h',     0,    18, 'v',     0,  38],
    ['MODIS Tile SIN',  'MODIS Sinusoidal',    'h',     0,    35, 'v',     0,  17],
    ['WELD ALASKA Tile','WELD ALASKA Tile',    'h',     0,    16, 'v',     0,  13],
    ['WELD CONUS Tile', 'WELD CONUS Tile',     'h',     0,    32, 'v',     0,  21],
    ['WRS-1',           'WRS-1 (Landsat 1-3)', 'path',  1,   251, 'row',   1, 248],
    ['WRS-2',           'WRS-2 (Landsat 4+)',  'path',  1,   233, 'row',   1, 248]
  ]

  availableSystems = for system in config
    [name, label, a0label, a0min, a0max, a1label, a1min, a1max] = system
    a0 = new GridAxis(a0label, a0min, a0max)
    a1 = new GridAxis(a1label, a1min, a1max)
    new Grid(name, label, a0, a1)

  class GridCondition extends KnockoutModel
    constructor: ->
      @available = availableSystems
      @selected = ko.observable(null)
      @coordinates = ko.observable(null)

      @error = @computed =>
        coordinates = @coordinates()?.trim()
        if coordinates? && coordinates.length > 0
          coords = coordinates.split(/\s+/)
          for coord in coords
            ranges = coord.split(',')
            return "Coordinate must be two comma-separated numbers: #{coord}" unless ranges.length == 2
            for range in ranges
              match = range.match(/^(\d+)(?:-(\d+))?$/)
              unless match?
                return "Invalid coordinate: #{range}"
              [all, min, max] = match
              min = parseInt(min, 10)
              max = parseInt(max, 10)
              return "Range minimum is greater than its maximum: #{range}" if min > max
        null

      @queryCoordinates = @computed
        read: =>
          coords = @coordinates()
          if coords?
            coords
              .trim()
              .replace(/,/g, ':')
              .replace(/\s+/g, ',')
              .replace(/(^|,)(\d+)($|:)/g, '$1$2-$2$3')
              .replace(/(^|:)(\d+)($|,)/g, '$1$2-$2$3')
          else
            null

        write: (param) =>
          coords = null
          if param?
            coords = param.replace(/,/g, ' ').replace(/:/g, ',').replace /(\d+)-(\d+)/g, (m, m0, m1) ->
              if m0 == m1 then m0 else m
          @coordinates(coords)

      @queryCondition = @computed
        read: =>
          selected = @selected()
          if selected
            condition = {name: selected.name}
            condition.coordinates = @queryCoordinates() if @queryCoordinates() && !@error()
            condition
          else
            null

        write: (params) =>
          name = params?.name
          systems = (sys for sys in @available when sys.name == name)
          @selected(systems[0])
          @queryCoordinates(params?.coordinates)

      @hint = @computed =>
        sel = @selected()
        if sel?
          "Enter #{sel.axis0.label} and #{sel.axis1.label} coordinates separated by spaces, e.g. \"2,3 5,7 8,8\""
        else
          "Choose a coordinate system"

    clear: ->
      window.edsc.page.ui.spatialType.isGrid(false)
      @selected(null)
      @coordinates(null)

  exports = GridCondition