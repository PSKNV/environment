command: "echo $(x=$(chunkc tiling::query -d id);echo $(chunkc tiling::query -D $(chunkc tiling::query -m id))\",$x\")"

refreshFrequency: 1000

render: (output) ->
  values = output.split(',')
  spaces = values[0].split(' ')

  htmlString = """
    <div class="currentDesktop-container" data-count="#{spaces.length}">
      <ul>
  """

  for i in [0..spaces.length - 1]
    switch spaces[i]
      when '1' then txt = ""
      when '2' then txt = ""
      when '3' then txt = ""
      else txt = ""
    htmlString += "<li id=\"desktop#{spaces[i]}\"><span class='white big_text'>#{txt}</span></li>"

  htmlString += """
      <ul>
    </div>
  """

style: """
  position: relative
  margin-top: 2px
  ul
    list-style: none
    margin: 0 0 0 10px
    padding: 0
  li
    display: inline
    margin: 0 10px
  li.active
    color: #ededed
    border-bottom: 2px solid #ededed
"""

update: (output, domEl) ->
  values = output.split(',')
  spaces = values[0].split(' ')
  space = values[1]

  htmlString = ""
  for i in [0..spaces.length - 1]
    switch spaces[i]
      when '1' then txt = ""
      when '2' then txt = ""
      when '3' then txt = ""
      else txt = ""
    htmlString += "<li id=\"desktop#{spaces[i]}\"><span class='white big_text'>#{txt}</span></li>"

  if ($(domEl).find('.currentDesktop-container').attr('data-count') != spaces.length.toString())
     $(domEl).find('.currentDesktop-container').attr('data-count', "#{spaces.length}")
     $(domEl).find('ul').html(htmlString)
     $(domEl).find("li#desktop#{space}").addClass('active')
  else
    $(domEl).find('li.active').removeClass('active')
    $(domEl).find("li#desktop#{space}").addClass('active')