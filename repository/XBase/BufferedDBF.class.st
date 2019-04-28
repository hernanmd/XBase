Class {
	#name : #BufferedDBF,
	#superclass : #DBF,
	#instVars : [
		'buffer',
		'bufferInterval'
	],
	#category : #'XBase-Base'
}

{ #category : #'as yet unclassified' }
BufferedDBF >> gotoRecord: recordNumber [ 
	"position currentRecord to recordNumber"

	(bufferInterval includes: recordNumber) ifFalse: [
		(recordNumber <= nRecords and: [recordNumber > 0]) 
			ifFalse: [^self error: 'Record number outside file bounds'].
		fileStream position: headerSize + ((recordNumber - 1) * recordSize).
		bufferInterval := recordNumber to: (nRecords min: (recordNumber + 49)).
		buffer := (fileStream next: (bufferInterval size * recordSize)) readStream.
		].
	buffer position: (recordNumber - bufferInterval first) * recordSize.
	self currentRecordIndex: recordNumber
]

{ #category : #'as yet unclassified' }
BufferedDBF >> open [
	"Open an existing .DBF file in binary mode and copy the bytes into the <fileStream> instance variable"
	"the dbf will be closed..."

	fileStream := (XBaseFile dbfBytesFrom: fileName) readStream.
	self isDBFFile
		ifTrue: [self modified: false.
			self getDBFInfos.
			bufferInterval := 1 to: (nRecords min: 50).
			buffer := (fileStream next: (bufferInterval size * recordSize)) readStream.
			self currentRecordIndex: 1.
			^ self]
		ifFalse: [fileStream close.
			^ self error: fileName , ': is not a .DBF file']
]

{ #category : #'as yet unclassified' }
BufferedDBF >> recordDataFast [
	"answer anArray with all the data in the current record (as Smalltalk objects, not bytes)"
	"2009-08-12 CBC - Super fast is to bypass getRecord and read/convert here, without the interim byte values.  This should
		only be called if getRecord hasn't been called first, but all of the requirements of getReocrd is met.
		Read the whole record in, then parse in memory."
	| data |

	recordBytes := nil.
	data := Array new: nFields.
	self deleted: buffer next = 42.	"first Byte is deleted-flag. 16r20 32 for valid, and 16r2A 42 for deleted"
	self deleted ifTrue: [
		XBaseDeletedRecord signal.  "Allow for special handling on deleted records."
		^data
		].
	1 to: nFields
		do: [:i | 
			data at: i put: ((readBlocks at: i) value: self value: (buffer next: ((fieldFormats at: i) at: 2))).
		].
^data		

]
