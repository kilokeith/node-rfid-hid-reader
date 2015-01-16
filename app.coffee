require 'colors'
_ 			= require 'lodash'
async 		= require 'async'
# usb 		= require 'usb'
# serialport 	= require 'serialport'
HID			= require 'node-hid'
When 		= require 'when'

tables  	= require "./configs/tables" 

### RFID Reader
Product ID:	0x3bfa    - 15354
Vendor ID:	0x0c27    - 3111
Version:	8.30
Speed:	Up to 1.5 Mb/sec
Manufacturer:	RFIDeas
Location ID:	0x14113000 / 24      - 336670720
Current Available (mA):	500
Current Required (mA):	100

{ vendorId: 3111,
		productId: 15354,
		path: 'USB_0c27_3bfa_14113000',
		serialNumber: '',
		manufacturer: 'RFIDeas',
		product: 'USB Keyboard',
		release: 2096,
		interface: -1,
		usagePage: 1,
		usage: 6 },


{ busNumber: 20,
		deviceAddress: 24,
		deviceDescriptor:
		 { bLength: 18,
			 bDescriptorType: 1,
			 bcdUSB: 272,
			 bDeviceClass: 0,
			 bDeviceSubClass: 0,
			 bDeviceProtocol: 0,
			 bMaxPacketSize0: 8,
			 idVendor: 3111,
			 idProduct: 15354,
			 bcdDevice: 2096,
			 iManufacturer: 1,
			 iProduct: 2,
			 iSerialNumber: 0,
			 bNumConfigurations: 1 } }
###



buffer = ''


#try to get RFID reader
getRFIDReader = ->
	deferred = When.defer()

	devices = HID.devices()
	rfidreader = _.find devices, (d) -> d.manufacturer is 'RFIDeas'

	if rfidreader? and rfidreader.path?
		deferred.resolve new HID.HID( rfidreader.path )
	else
		deferred.reject new Error('no rfid reader found')

	deferred.promise



readIDs = (data) ->
	shift = data[0] is 2
	key = data[2]
	table = if shift then tables.shift_hid else tables.hid

	if table?[key]?
		buffer += table[key]

	if buffer.length >= 13
		console.log "rfid is:".green, buffer
		buffer = ''

deviceError = (err) ->
	console.error 'RDIF read error'.red, err


#get rfid device
getRFIDReader().then (device) ->
	#setup device events
	device.on "data", readIDs
	device.on "error", deviceError

.catch (err) ->
	console.error 'No RFID reader found'.red, err
	prcoess.exit(0)