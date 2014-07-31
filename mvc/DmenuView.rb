class DmenuView

  # turn MenuStructs into dmenu objects
  
  # makes new menus
  require 'dmenu'
  # procedures to generate menu rows from data
  require_relative './../menu_struct/MusicMenus'
  include MusicMenus
  # print mpd state info, play/pause, random, etc
  require_relative './../mpd/MpdStatus'
  include MpdStatus

  def initialize (model)
    @mpd = model
  end

  # basic settings for all menus
  def dmenu_base
    menu = Dmenu.new
    menu.position = :bottom
    menu.font = 'Sans-10'
    menu.case_insensitive = true
    menu.lines = 20
    return menu
  end
  
  # create a dmenu object from a MenuStruct item
  def build_menu (menu_struct)
    menu = dmenu_base
    menu.prompt = menu_struct.prompt
    # check for rows to dynamically generate
    rows = menu_struct.rows.flat_map do |row|
      (row.instance_of? RowsOf) ? build_rows(row) : row
    end
    # turn rows into dmenu items
    items = rows.map do |row|
      # if text is a symbol, execute as a method that returns needed text line
      text = (row.text.is_a? Symbol) ? send(*row.text) : row.text
      Dmenu::Item.new(text, row.action)
    end
    menu.items = items
    return menu
  end
  
  # return an array of Row structs generated with information 
  # from a RowsOf struct
  def build_rows (multirow)
    # get array of data, then make one new row for each element
    case multirow.data_set
    when 'queued_tracks'
      # first track in queue is the currently playing track
      # max of 98 tracks (5 menu screens) for display speed
      first_pos = @mpd.current_song ? @mpd.current_song.pos : 0
      last_pos = 97 + first_pos
      data = @mpd.queue(first_pos .. last_pos)
    when 'artists'
      data = @mpd.artists
    when 'albums' 
      data = @mpd.albums(multirow.filter)
    when 'tracks'
      data = @mpd.where(:album => multirow.filter)
    end
    format_rows(data, multirow.formatter)
  end
  
  # format each Row struct as specified by the formatter proc
  def format_rows (data, formatter)
    # call the proc in MusicMenus for each row
    data.map do |row_data|
      formatter.call(row_data)
    end
  end
  
end
