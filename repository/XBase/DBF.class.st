Class {
	#name : #DBF,
	#superclass : #XBaseFile,
	#category : #'XBase-Base'
}

{ #category : #examples }
DBF class >> example1 [
	"some examples (replace by your pathnames). No need to close files!"
	"DBF example1"

"	^ (self on: 'c:\etcovers\smalland\pat.dbf') inspect"
"	^ (self on: 'c:\etcovers\b_hoe\pat.dbf') inspect"
	^ (self on: 'd:\etcovers\vole3\pat.dbf') "contentsWithFields"
"	^ (self on: 'C:\etarcview\bushcricket\withET_CLASS\smallstepsCONV.dbf') inspect"
"	^ (self on: 'C:\etarcview\bushcricket\withET_CLASS\test4.dbf') inspect"
"	^ (self on: 'C:\hansdocs\projecten\laura\hansaantal.dbf') inspect"
]

{ #category : #private }
DBF >> appendEndOfFileFlag [
	"set the end of file flag after the last record"

	| lastPos |
	lastPos := headerSize + ( nRecords * recordSize). 
	[fileStream position = lastPos] whileFalse: [fileStream nextNumber: 1 put: 0].
	fileStream position: lastPos.
	^fileStream nextPut: 26
]

{ #category : #'open/close' }
DBF >> close [
	"Do only the modification test (saving last edited record) and KEEP the bytes..."

	self modificationTest.			"current record will be saved"
	fileStream size > 200000000 ifTrue: [fileStream close].

]

{ #category : #writing }
DBF >> dbfBytesToFile: aString [ 
	"Open the file aString in binary mode and copy the bytes from <fileStream> into the file"

	"| dbf | 
	dbf := DBF example1.
	dbf writeOnFile: 'example1.dbf' "

	| aStream writingBlock |
	aStream := aString asFileReference binaryReadStream.
	writingBlock := [aStream nextPutAll: fileStream contents].
	writingBlock ensure: [aStream close]
]

{ #category : #'open/close' }
DBF >> open [
	"Open an existing .DBF file in binary mode and copy the bytes into the <fileStream> instance variable"
	"the dbf will be closed..."

	fileStream := (XBaseFile dbfBytesFrom: fileName) readStream.
	self isDBFFile
		ifTrue: [self modified: false.
			self getDBFInfos.
			self goto: 1.
			^ self]
		ifFalse: [fileStream close.
			^ self error: fileName , ': is not a .DBF file']
]

{ #category : #private }
DBF >> saveFieldsInfos [
	"commit the field formats to the internal bytes stream"
	| pos |
	pos := 32.
	[fileStream position = 32] whileFalse: [fileStream nextNumber: 1 put: 0].
	fileStream position: 32.
	fieldFormats
		with: fields
		do: [:info :name | 

			[fileStream position = (pos + 32)] whileFalse: [fileStream nextNumber: 1 put: 0]. "make sure we can read the next 32 bytes - jmb"

			"fileStream position: pos.
			(ByteArray new: 11 withAll: 0)
				do: [:byte | fileStream nextPut: byte]. "
			"erase the previous contents"
			fileStream position: pos.			"back to position: pos"
			name asByteArray
				do: [:byte | fileStream nextPut: byte].
			"Field name: 10 characters; 11th byte = 0"
			fileStream position: pos + 11.
			fileStream nextPut: (info at: 1) asInteger.



			"Field type"
			(info at: 1)
					== $C
				ifTrue: [fileStream position: pos + 16;
						
						nextPutAll: (self
								num2Bytes: (info at: 2)
								size: 2)]
				ifFalse: [fileStream position: pos + 16;
						
						nextPutAll: (self
								num2Bytes: (info at: 2)
								size: 1).
					"Field length"
					fileStream position: pos + 17;
						
						nextPutAll: (self
								num2Bytes: (info at: 3)
								size: 1)].
			fileStream position: pos + 20;
				
				nextPutAll: (self num2Bytes: 1 size: 1).
			"work area id - not really relevant"
			fileStream position: pos + 31;
				
				nextPutAll: (self num2Bytes: 0 size: 1).
			"ignore index field"
			pos := pos + 32].
	fileStream position: pos
]
