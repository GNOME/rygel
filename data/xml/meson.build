xml_processor = find_program('process-xml.py')
xml_dir = join_paths(rygel_datadir, 'xml')

server_xml = configure_file(input: 'MediaServer3.xml.in.in',
               output: 'MediaServer3.xml.in',
               configuration: plugin_config)

renderer_xml = configure_file(input: 'MediaRenderer2.xml.in.in',
               output: 'MediaRenderer2.xml.in',
               configuration: plugin_config)

ruih_xml = configure_file(input: 'RuihServer2.xml.in.in',
               output: 'RuihServer2.xml.in',
               configuration: plugin_config)


# Fixme: How to install this...
#xml_files = xml_processor.process(['EnergyManagement.xml.in',
#                       'ContentDirectory.xml.in',
#                       'ContentDirectory-NoTrack.xml.in',
#                       'ConnectionManager.xml.in',
#                       'RemoteUIServerService.xml.in',
#                       'AVTransport2.xml.in',
#                       'RenderingControl2.xml.in',
#                       'UIList.xml.in',
#                       'BasicManagement2.xml.in',
#                       'X_MS_MediaReceiverRegistrar1.xml.in'],
#                       install: true,
#                       install_dir : xml_dir)

custom_target('EnergyManagement.xml',
              input: 'EnergyManagement.xml.in',
              output: 'EnergyManagement.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('MediaServer3.xml',
              input: server_xml,
              output: 'MediaServer3.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('MediaRenderer2.xml',
              input: renderer_xml,
              output: 'MediaRenderer2.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('ContentDirectory.xml',
              input: 'ContentDirectory.xml.in',
              output: 'ContentDirectory.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('RuihServer2.xml',
              input: ruih_xml,
              output: 'RuihServer2.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('ContentDirectory-NoTrack.xml',
              input: 'ContentDirectory-NoTrack.xml.in',
              output: 'ContentDirectory-NoTrack.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('ConnectionManager.xml',
              input: 'ConnectionManager.xml.in',
              output: 'ConnectionManager.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('RemoteUIServerService.xml',
              input: 'RemoteUIServerService.xml.in',
              output: 'RemoteUIServerService.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)
custom_target('AVTransport2.xml',
              input: 'AVTransport2.xml.in',
              output: 'AVTransport2.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('RenderingControl2.xml',
              input: 'RenderingControl2.xml.in',
              output: 'RenderingControl2.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('UIList.xml',
              input: 'UIList.xml.in',
              output: 'UIList.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('BasicManagement2.xml',
              input: 'BasicManagement2.xml.in',
              output: 'BasicManagement2.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)

custom_target('X_MS_MediaReceiverRegistrar1.xml',
              input: 'X_MS_MediaReceiverRegistrar1.xml.in',
              output: 'X_MS_MediaReceiverRegistrar1.xml',
              capture: true,
              command : [xml_processor, '@INPUT@'],
              install: true,
              install_dir : xml_dir)
