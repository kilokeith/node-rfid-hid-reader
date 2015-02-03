path 		= require 'path'
_ 			= require 'lodash'
async 		= require 'async'
HID			= require 'node-hid'
When 		= require 'when'

tables  	= require path.join( global.__base, "configs", "tables" )

# tag_length	= 13
tag_length	= 8
# how many empty reads before we can assume input has ended?
empty_reads_mark_finish = 5

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
empty_reads = 0
listen_for_empty = false

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



readIDs = (data, cb) ->
	shift = data[0] is 2
	key = data[2]
	table = if shift then tables.shift_hid else tables.hid

	# console.log typeof key, key

	if table?[key]?
		buffer += table[key]
		# start listening for empty reads
		empty_reads = 0
		listen_for_empty = true

	else if data[0] is 0 and data[2] is 0
		#read was empty
		empty_reads += 1 if listen_for_empty
		


	# if buffer.length >= tag_length
	# if we hit X empty reads, stop listening and output RFID buffer string
	if empty_reads >= empty_reads_mark_finish
		empty_reads = 0
		listen_for_empty = false
		console.log "rfid is:".green, buffer
		buffer = ''

deviceError = (err, cb) ->
	console.error 'RDIF read error'.red, err





module.exports = (idReadCb=null, errorCB=null) ->
	#get rfid device
	getRFIDReader().then (device) ->
		#setup device events
		device.on "data", (data) ->
			readIDs data, idReadCb


		device.on "error", (err) ->
			deviceError err, errorCB

	.catch (err) ->
		console.error 'No RFID reader found'.red, err
		prcoess.exit(0)