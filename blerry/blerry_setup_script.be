import path
def start_blerry_setup()
  var cl = webclient()
  var url = 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev-blerry2/blerry2/blerry_setup.be'
  cl.begin(url)
  var r = cl.GET()
  if r != 200
    print('error getting blerry_setup.be')
    return false
  end
  var s = cl.get_string()
  cl.close()
  var f = open('blerry_setup.be', 'w')
  f.write(s)
  f.close()
  load('blerry_setup.be')
end
start_blerry_setup()
