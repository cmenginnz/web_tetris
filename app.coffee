piece = angular.module 'piece', [];

class Matrix


    get_blank_line: ->
        return ('white' for [1..@width])

    constructor: (width = 10, height = 20) ->
        @width = width
        @height = height
        @matrix = (@get_blank_line() for [1..height])
        @interval = 500
        @deleted_lines = 0

    dump: ->
        @matrix

    is_line_full: (line) ->
        for block in @matrix[line]
            return false if block == 'white'
        return true

    delete_line: (line) ->
        @deleted_lines++
        @matrix[1..line] = @matrix[0..line-1]
        @matrix[0] = @get_blank_line()

    clean_line: (line) ->
        @delete_line(line) if @is_line_full(line)

    clean_matrix: ->
        @deleted_lines = 0
        for i in [0..@height-1]
            @clean_line(i)
        return @deleted_lines

    clean_all: ->
        @matrix = (@get_blank_line() for [1..@height])

class Piece
    constructor: (matrix, preview_matrix) ->
        @type = Math.floor((Math.random() * 7))

        pieces = [
            [ [0, 0],  [0, 1], [1, 0],  [1, 1]  ],  # O
            [ [-1, 0], [0, 0], [1, 0],  [2, 0]  ],  # I
            [ [-1, 0], [0, 0], [1, 0],  [1, 1]  ],  # J
            [ [-1, 0], [0, 0], [1, 0],  [-1, 1] ],  # L
            [ [0, 0],  [1, 0], [-1, 1], [0, 1]  ],  # S
            [ [-1, 0], [0, 0], [1, 0],  [0, 1]  ],  # T
            [ [-1, 0], [0, 0], [0, 1],  [1, 1]  ],  # Z
        ]

        colors = [ "darkred", "orange", "darkmagenta", "darkcyan", "darkblue", "lime", "darkgray" ]

        @x = 4
        @y = 0
        @piece = pieces[@type]
        @color = colors[@type]
        @matrix_dump = matrix.dump()


        preview_matrix.clean_all()
        @preview_matrix_dump = preview_matrix.dump()
        @do_preview_apply(@preview_matrix_dump)

    do_rotate: ->
        console.log @piece
        @piece = ([-block[1], block[0]] for block in @piece)
        console.log @piece

    do_un_rotate: ->
        @piece = ([block[1], -block[0]] for block in @piece)

    do_down: ->
        @y++

    do_up: ->
        @y--

    do_left: ->
        @x--

    do_right: ->
        @x++

    do_preview_apply: (matrix_dump) ->
        for block in @piece
            tmp_x = 1 + block[0]
            tmp_y = 1 + block[1]
            matrix_dump[tmp_y][tmp_x] = @color


    do_apply: (matrix_dump, apply = true) ->
        for block in @piece
            tmp_x = @x + block[0]
            tmp_y = @y + block[1]
            if apply
                if not matrix_dump[tmp_y] or matrix_dump[tmp_y][tmp_x] != "white"
                    return false;
            matrix_dump[tmp_y][tmp_x] = if apply then @color else "white"
        return true;

    apply: ->
        tmp_matrix_dump = JSON.parse(JSON.stringify(@matrix_dump))
        if @do_apply tmp_matrix_dump
            @do_apply @matrix_dump
            return true
        else
            return false

    un_apply: ->
        @do_apply @matrix_dump, false

    act: (action, un_action) ->
        @un_apply(@matrix_dump)
        action.call(this)
        if not @apply(@matrix_dump)
            un_action.call(this)
            @apply(@matrix_dump)
            return false
        else
            return true

    down: ->
        @act @do_down, @do_up

    left: ->
        @act @do_left, @do_right

    right: ->
        @act @do_right, @do_left

    rotate: ->
        @act @do_rotate, @do_un_rotate if @type  # piece O does not rotate


app = angular.module 'tetris', [];

app.controller('MainCtrl', ($scope, $timeout) ->
    is_die = false
    is_playing = 1
    timmer = 0

    do_new_piece = ->
        new Piece $scope.matrix, $scope.preview_matrix

    new_piece = ->
        $scope.next_piece = $scope.next_piece ? do_new_piece()

        $scope.piece = $scope.next_piece
        $scope.piece.apply()

        $scope.next_piece = do_new_piece()

    die = ->
        is_die = true;

    down = ->
        if not $scope.piece.down()
            if $scope.piece.y
                del_lines = $scope.matrix.clean_matrix()
                $scope.score += del_lines ** 2 * 10
                new_piece()
            else
                die()
            return false
        else
            return true

    down_to_bottom = ->
        r = true
        r = down() while r;

    bind_key = ->
        $scope.on_keypress = (event) ->
            key = event.which
            console.log key
            if is_die
                return
            switch key
                when 37 then $scope.piece.left()
                when 38 then $scope.piece.rotate()
                when 39 then $scope.piece.right()
                when 40 then down()
                when 32 then down_to_bottom()

    do_autodown = ->
        down()
        enable_autodown()


    enable_autodown = ->
        $timeout.cancel(timmer) if timmer
        if (is_playing)
            timmer = $timeout(do_autodown, 1000)

    init = ->
        $scope.matrix = new Matrix
        $scope.preview_matrix = new Matrix(4, 4)
        $scope.matrix_dump = $scope.matrix.dump()
        $scope.preview_matrix_dump = $scope.preview_matrix.dump()
        $scope.score = 0
        new_piece()
        is_die = false
        bind_key()
        enable_autodown()

    init();
);