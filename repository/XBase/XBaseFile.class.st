"
A Smalltalk class giving full access to Xbase (dBASE) files (dBASE III/IV). Hans Baveco, November 3, 2004.
A rewrite of a Squeak goodie (XBase, version 1.00, published Feb 13, 1998 by andavino@tin.it). Ported to VisualWorks, back-ported to Squeak!


Open a dbf file with:
	| dbf | 
	""dbf := XBaseFile on: 'd:\DBF\allotments.dbf'. ""
	dbf := XBaseFile on: 'D:\etarcview\berisp\subcad.dbf'. 
""or""
	dbf := XBaseFile fromUser.
	dbf inspect.
""Close it with:""
	dbf close
	
Retrieve the contents of a dbf with:
	XBaseFile recordsFromFile: 'd:\DBF\allotments.dbf'. 
or
	XBaseFile recordsFromUser.
The file does not need to be explicitly closed now.
If you want to have the field(labels) as well:
	XBaseFile recordsAndFieldsFromFile: 'd:\DBF\allotments.dbf'. 
or
	XBaseFile recordsAndFieldsFromUser.


Create a new dbf file with the on:fields: method, e.g.:
	| dbf rng |
	dbf := XBaseFile on: 'testEdit' fields: 
		{#( 'abc' $N 5 0 nil). #( 'et_class' $C 12 0 nil). #( 'perimeter' $F 20 3 nil). #( 'logical' $L 1 0 nil)}.
""4 fields, but still empty. Add records:""
	rng := Random new. rng seed: 2345678901.
	1 to: 10
		do: 
			[:ix | 
			dbf append.
			dbf atFieldName: 'ABC' put: ix.
			dbf atFieldName: 'ET_CLASS' put: 'MyClass', ix printString.
			dbf atFieldName: 'PERIMETER' put: ix  * 123456.12345.
			dbf atFieldName: 'LOGICAL' put: (rng next > 0.5)].
	""if you know the index of a field, use the faster atField: anInteger put: fieldValue, instead of atFieldName: anInteger put: fieldValue""
	dbf saveRecord. ""make sure the last record is also saved""
	dbf inspect. ""and dbf contents""
	dbf close ""dont forget, or do XBaseFile allInstances do: [:each | each close]""
	
======================================================================================================
 Instance Variables:
	filterArray		-- Array with Blocks|nil	-- blocks that return true for [] value: self will lead to skipping the record
	lastUpdate		-- Data					-- date of last save
	fileName		-- String				-- name of currently open file
	fileStream		-- StandardFileStream	-- the open stream
	headerSize		-- Integer				-- size of header in bytes
	nRecords		-- Integer				-- number of records
	currentRecordIndex	-- Integer			-- index of selected record
	deleted			-- Boolean				-- indicates whether selected record is in fact deleted
	modified		-- Boolean				-- indicates whether selected record is modified
	eof				-- Boolean				-- end of file condition
	bof				-- Boolean				-- begin of file condition
	recordBytes		-- Array with ByteArrays	-- bytes in the current record (each field a ByteArray)
	readBlocks		-- Ord.Coll. with Blocks	-- each BlockContext defines how to read a field
	writeBlocks		-- Ord.Coll. with Blocks	-- each BlockContext defines how to write a field
	fields			-- Array with Strings	-- each string defines the name of a field (in UPPERCASE)
	nFields			-- Integer				-- the number of fields
	fieldsFormats	-- Ord.Coll. with Arrays	-- each array with 4 elements: fieldtype, fieldsize, decimals, fieldoffset in record
	fieldIndices		-- Dictionary			-- linking name of field (keys), to index in fieldFormats (value)

======================================================================================================
Record Header Structure of a DBF file (see http://www.e-bachmann.dk/docs/xbase.htm):
byte
---------------------------------------------------------------------------
0	Version number
----------------------------------------------------------------------------
1	Date of last update - year (0=1900)
2	Date of last update - month
3	Data of last update - day of month
---------------------------------------------------------------------------
4	Number of records (32 bits)
5
6
7
---------------------------------------------------------------------------
8	Length of header structure (16 bits)
9	
---------------------------------------------------------------------------
10	Length of each record (16 bits)
11
---------------------------------------------------------------------------
12	- 31 Reserved, etc, etc
---------------------------------------------------------------------------
32	Field Descriptor array (max 128 fields)
	Per field 32 bytes (0 - 31), see description below
n	n = 32 + fields*32 (or in numbers of bytes: 33 + fields*32)
-----------------------------------------------------------------------------
n+1	Terminator (16r0D = 13)
-----------------------------------------------------------------------------
m	Database Container
m+263	(Something related to Visual FoxPro) WITHIN THE HEADER STRUCTURE!
-----------------------------------------------------------------------------


Now the Field Descriptor array:
byte
0	Field name in ASCII
10	(terminated by 16r00)
-----------------------------------------------------------------------------
11	Field type (ASCII)
-----------------------------------------------------------------------------
12	Field data address
15	(IRRELEVANT?)
-----------------------------------------------------------------------------
16	Field length
-----------------------------------------------------------------------------
17	Decimal count
-----------------------------------------------------------------------------
18	(reserved for multi-user dBASE)
19
-----------------------------------------------------------------------------
20	Work area ID (16r01 in all dBASE III files)
-----------------------------------------------------------------------------
20	(reserved for multi-user dBASE)
21
-----------------------------------------------------------------------------
23	Flag for SET FIELDS
-----------------------------------------------------------------------------
24	RESERVED
30
-----------------------------------------------------------------------------
31	Index field flag (dBASE IV, 16r00 -> ignored)
-----------------------------------------------------------------------------

And finally, record structure:

0	Field deleted flag 16r2A=42 (deleted) or 16r20=32 (valid)
-----------------------------------------------------------------------------
	Data (ASCII)
-----------------------------------------------------------------------------
	Field deleted flag etc (second field)
"
Class {
	#name : #XBaseFile,
	#superclass : #Object,
	#instVars : [
		'filterArray',
		'lastUpdate',
		'fileName',
		'fileStream',
		'headerSize',
		'recordSize',
		'nRecords',
		'currentRecordIndex',
		'deleted',
		'modified',
		'eof',
		'bof',
		'recordBytes',
		'readBlocks',
		'writeBlocks',
		'fields',
		'nFields',
		'fieldFormats',
		'fieldIndices',
		'fieldIndicesUC'
	],
	#category : #'XBase-Base'
}

{ #category : #bytes }
XBaseFile class >> dbfBytesFrom: aString [
	"XBaseFile dbfBytesFrom: 'D:\etarcview\berisp\subcad.dbf'"

	| stream bytes |
	stream := aString asFileReference readStream binary.
	stream size > 200000000 ifTrue: [
		stream setConverterToLatin1.
		^ stream ].
	bytes := [stream contents]
				ensure: [stream close].
	^bytes
]

{ #category : #examples }
XBaseFile class >> example1 [
	"some examples (replace by your pathnames)"
	"XBaseFile example1"
	"dont forget to send <close> to the inspected instance. Otherwise, execute cleanup code: ' XBaseFile allInstances do: [:each | each close]' "

"	^ (self on: 'c:\etcovers\smalland\pat.dbf') inspect"
"	^ (self on: 'c:\etcovers\b_hoe\pat.dbf') inspect"
	^ (self on: 'c:\etcovers\vole3\pat.dbf') inspect
"	^ (self on: 'C:\etarcview\bushcricket\withET_CLASS\smallstepsCONV.dbf') inspect"
"	^ (self on: 'C:\etarcview\bushcricket\withET_CLASS\test4.dbf') inspect"
"	^ (self on: 'C:\hansdocs\projecten\laura\hansaantal.dbf') inspect"
]

{ #category : #examples }
XBaseFile class >> exampleContents [
	"some examples (replace by your pathnames)"
	"self exampleContents"
	
"	(self recordsFromFile: 'c:\etcovers\smalland\pat.dbf') inspect"
"	(self recordsFromFile: 'c:\etcovers\b_hoe\pat.dbf') inspect"
"	(self recordsFromFile: 'C:\etarcview\bushcricket\withET_CLASS\smallstepsCONV.dbf') inspect"
	
"	(self recordsAndFieldsFromFile: 'c:\etcovers\smalland\pat.dbf') inspect"
"	(self recordsAndFieldsFromFile: 'c:\etcovers\b_hoe\pat.dbf') inspect"
"	(self recordsAndFieldsFromFile: 'C:\etarcview\bushcricket\withET_CLASS\smallstepsCONV.dbf') inspect"

"	^self recordsAndFieldsFromUser inspect"
	^self recordsFromUser inspect
]

{ #category : #'instance creation' }
XBaseFile class >> fields: fields [
	"create a new DBFile object, with the bytes in an IN-MEMORY stream"
	"Fields is a sequential collection with Arrays defining name and format of each field:
		1) name, aString (automatically converted into UPPERCASE)
		2) a character indicating field type ($C -> Character, $N Numeric, $L Logical, $D Date)
		3) field length
		4) decimal positions (not relevant if field is not Numeric)
		5) nil (reserved for some? use)
	e.g. Array with: 'INTERNAL_ID' with: $N with: 5 with: 0 with: nil"

	^(super basicNew) memoryCreate: fields
]

{ #category : #'instance creation' }
XBaseFile class >> fromUser [
	"XBaseFile fromUser"
	"XBaseFile fromUser contents"	
	" XBaseFile allInstances do: [:each | each close] "

	| menu result |
	
	menu := UIManager default chooseFullFileNameMatching: (Array with: '*.dbf')	.
"	result := menu startUpWithCaption: 'Select DBF to open...'."
	result
		ifNil: [^ nil].
	^self on: ( result directory fullNameFor: result name)
]

{ #category : #'instance creation' }
XBaseFile class >> on: fileName [ 
	"open a DBFile object on an existing .DBF file, named fileName (String or Symbol, optionally including file path"

	^(super basicNew setName: fileName asString) open
]

{ #category : #'instance creation' }
XBaseFile class >> on: fileName fields: fields [
	"create a new DBFile object, with an OPEN file stream"
	"fileName sets the name of the file. Optionally it includes the file path. Fields is a sequential collection with Arrays defining name and format of each field:
		1) name, aString (automatically converted into UPPERCASE)
		2) a character indicating field type ($C -> Character, $N Numeric, $L Logical, $D Date)
		3) field length
		4) decimal positions (not relevant if field is not Numeric)
		5) nil (reserved for some? use)
	e.g. Array with: 'INTERNAL_ID' with: $N with: 5 with: 0 with: nil"

	^(super basicNew setName: fileName asString) create: fields
]

{ #category : #'file contents' }
XBaseFile class >> recordsAndFieldsFromFile: aString [ 
	"retrieve all records from file named aString. As an additional record, 
	add the field labels. Close the file before returning"
	| file records |
	file := XBaseFile on: aString.
	[Cursor read
		showWhile: [records := file contentsWithFields]]
		ensure: [file close].
	^ records
]

{ #category : #'file contents' }
XBaseFile class >> recordsAndFieldsFromUser [
	"answer the records in a user-selected file. As an additional record, add the field labels. File will be closed before returning"
	"XBaseFile recordsAndFieldsFromUser"

	| menu result |
	menu := UIManager default chooseFullFileNameMatching: (Array with: '*.dbf').
"	result := menu startUpWithCaption: 'Select DBF to open...'."
	result ifNil: [^ #()].
	^ self recordsAndFieldsFromFile: (result directory fullNameFor: result name)
]

{ #category : #'file contents' }
XBaseFile class >> recordsFromFile: aString [ 
	"retrieve all records from file named aString. Close the file before 
	returning "
	| file records |
	file := XBaseFile on: aString.
	[Cursor read
		showWhile: [records := file contents]]
		ensure: [file close].
	^ records
]

{ #category : #'file contents' }
XBaseFile class >> recordsFromUser [
	"answer the records in a user-selected file. File will be closed before returning"
	"XBaseFile recordsFromUser"
	| menu result |
	menu := UIManager default chooseFullFileNameMatching: (Array with: '*.dbf').
"	result := menu startUpWithCaption: 'Select DBF to open...'."
	result
		ifNil: [^ #()].
	^ self
		recordsFromFile: (result directory fullNameFor: result name)
]

{ #category : #testing }
XBaseFile class >> test [
	"create a dbf; add some filters"
	"XBaseFile test"
	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"

	| a b |
	b := OrderedCollection new.
	Transcript cr; show: 'Building new test xBase file ...'.
	b add: #('abc' $N 5 0 nil).
	a := XBaseFile on: #test fields: b. 
	1 to: 10
		do: 
			[:ix | 
			a append;
				atFieldName: 'ABC' put: ix "printString"].
	Transcript show: ' Done'.
	Transcript cr; show: 'Records in file ' , a records printString.
	Transcript cr; show: 'Setting filter on field ABC. Filter expression ''((dbf atFieldName: #abc) asNumber  == 2) not '' ...'.
	a setFilter: [:dbf | ((dbf atFieldName: #abc) asNumber  == 2) not ].
	Transcript show: ' Done'.
	Transcript cr; show: 'Start 1st test: Skipping forward from top ... '.
	a do: [:dbf | Transcript cr; show: dbf currentRecordIndex printString , ' -- ' , (dbf atFieldName: 'ABC') printString].
	Transcript show: ' Done'.
	Transcript cr; show: 'Start 2st test: Skipping backward from bottom ... '.
	a reverseDo: [:dbf | Transcript cr; show: dbf currentRecordIndex printString , ' -- ' , (dbf atFieldName: #abc) printString].
	Transcript cr; show: ' Done'.
	Transcript cr; show: 'Closing xBase test file and exiting ...'.
	a close.
	Transcript cr; show: ' Done'.
	^a
]

{ #category : #testing }
XBaseFile class >> testAfterEditing [
	"open the file that was created programmatically with #testEditing"

	"XBaseFile testAfterEditing"

	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"

	| dbf |
	dbf := XBaseFile on: 'testedit.dbf'.
	dbf halt.
	dbf close
]

{ #category : #testing }
XBaseFile class >> testEditing [
	"create a dbf with fieldtypes Number, Character, Float and Logical; add 10 records"
	"XBaseFile testEditing"
	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"

	| a b rng |
	rng := Random new.
	rng seed: 2345678901.
	b := OrderedCollection new.
	Transcript cr; show: 'Building new test xBase file ...'.
	b addLast: #( 'abc' $N 5 0 nil).
	b addLast: #( 'et_class' $C 12 0 nil).
	b addLast: #( 'perimeter' $F 20 3 nil).
	b addLast: #( 'logical' $L 1 0 nil).
	a := XBaseFile on: 'testEdit' fields: b. 
	1 to: 10
		do: 
			[:ix | 
			a append.
			a atFieldName: 'ABC' put: ix.
			a atFieldName: 'ET_CLASS' put: 'MyClass', ix printString.
			a atFieldName: 'PERIMETER' put: ix  * 123456.12345.
			a atFieldName: 'LOGICAL' put: (rng next > 0.5)].
	Transcript show: ' Done'.
	Transcript cr; show:  a records printString , 'Records in file '.
	Transcript cr; show: 'Start 1st test: Skipping forward from top ... '.
	a do: [:dbf | Transcript cr;
				show: dbf currentRecordIndex printString;
				tab; show:  (dbf atFieldName: 'ABC') printString;
				tab; show:  (dbf atFieldName: 'ET_CLASS') printString;
				tab; show:  (dbf atFieldName: 'PERIMETER') printString;
				tab; show:  (dbf atFieldName: 'LOGICAL') printString].
	Transcript cr; show: ' Done'. 
	Transcript cr; show: 'Closing xBase test file and exiting ...'.
	a close.
	Transcript show: ' Done'.
	^a
]

{ #category : #testing }
XBaseFile class >> testEditing2 [
	"create a dbf with fieldtypes Number, Character, Float and Logical; add 10 records"
	"XBaseFile testEditing2"
	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"

	| a b rng |
	rng := Random new.
	rng seed: 2345678901.
	b := OrderedCollection new.
	Transcript cr; show: 'Building new test xBase file ...'.
	b addLast: #( 'abc' $N 5 0 nil).
	b addLast: #( 'et_class' $C 12 0 nil).
	b addLast: #( 'perimeter' $F 24 12 nil).
	b addLast: #( 'logical' $L 1 0 nil).
	a := XBaseFile on: 'testEdit2' fields: b. 
	1 to: 10
		do: 
			[:ix | 
			a append.
			a atFieldName: 'ABC' put: ix.
			a atFieldName: 'ET_CLASS' put: 'MyClass', ix printString.
			a atFieldName: 'PERIMETER' put: (rng next  * 123456.12345).
			a atFieldName: 'LOGICAL' put: (rng next > 0.5)].
	Transcript show: ' Done'.
	Transcript cr; show:  a records printString , 'Records in file '.
	Transcript cr; show: 'Start 1st test: Skipping forward from top ... '.
	a do: [:dbf | Transcript cr;
				show: dbf currentRecordIndex printString;
				tab; show:  (dbf atFieldName: 'ABC') printString;
				tab; show:  (dbf atFieldName: 'ET_CLASS') printString;
				tab; show:  (dbf atFieldName: 'PERIMETER') printString;
				tab; show:  (dbf atFieldName: 'LOGICAL') printString].
	Transcript cr; show: ' Done'. 
	Transcript cr; show: 'Closing xBase test file and exiting ...'.
	a close.
	Transcript show: ' Done'.
	^a
]

{ #category : #testing }
XBaseFile class >> testFloats [
	"create a dbf with Float values"
	"XBaseFile testFloats"
	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"
	"NOTE: floats that after formatting do not fit into the field can not be trusted!
	It is the printString of the float that is stored, and it may use scientific notation" 

	| a b |
	b := OrderedCollection new.
	Transcript cr; show: 'Building new test xBase file ...'.
	b addLast: #( 'short' $F 18 0 nil). 
	b addLast: #( 'medium' $F 15 3 nil).
	b addLast: #( 'long' $F 20 3 nil).
	b addLast: #( 'num' $N 20 0 nil).
	b addLast: #( 'numdec' $N 20 3 nil).	
	a := XBaseFile on: 'testFloats' fields: b. 
	#(1234567.00008912345 1234567.00089123456 1234567.00891234567 1234567.08912345678 1234567.89123456789) 
		do: 
			[:ix | 
			a append.
			a atFieldName: 'SHORT' put: ix.
			a atFieldName: 'MEDIUM' put: ix.
			a atFieldName: 'LONG' put: ix.
			a atFieldName: 'NUM' put: ix.
			a atFieldName: 'NUMDEC' put: ix.						
			].
	Transcript show: ' Done'.
	Transcript cr; show:  a records printString , 'Records in file '.
	a do: [:dbf | Transcript cr;
				show: dbf currentRecordIndex printString;
				tab; show:  (dbf atFieldName: 'SHORT') printString;
				tab; show:  (dbf atFieldName: 'MEDIUM') printString;
				tab; show:  (dbf atFieldName: 'LONG') printString;
				tab; show:  (dbf atFieldName: 'NUM') printString;
				tab; show:  (dbf atFieldName: 'NUMDEC') printString							
				].
	Transcript cr; show: ' Done'. 
	Transcript cr; show: 'Closing xBase test file and exiting ...'.
	a close.
	Transcript show: ' Done'.
	^a
]

{ #category : #testing }
XBaseFile class >> testIntegers [
	"XBaseFile testIntegers"
	"cleanUp code: 'XBaseFile allInstances do: [:each | each close]'"
	"TAKE CARE TO MAKE THE FIELDSIZE LARGE ENOUGH!!!!"

	| a b |
	b := OrderedCollection new.
	Transcript cr; show: 'Building new test xBase file ...'.
	b addLast: #( 'short' $F 32 0 nil).
	b addLast: #( 'medium' $F 32 3 nil).
	b addLast: #( 'long' $F 32 3 nil).
	b addLast: #( 'num' $N 32 0 nil).
	b addLast: #( 'numdec' $F 32 3 nil).
	a := XBaseFile on: 'testIntegers' fields: b. 
	#(12345678901234 12345678901234567 123456789012345678 123456789012345678912 12345678901234567891234 123456789012345678912345678 )
		do: 
			[:ix | 
			a append.
			a atFieldName: 'SHORT' put: ix.
			a atFieldName: 'MEDIUM' put: ix.
			a atFieldName: 'LONG' put: ix.
			a atFieldName: 'NUM' put: ix.
			a atFieldName: 'NUMDEC' put: ix.
].
	Transcript show: ' Done'.
	Transcript cr; show: 'Records in file ' , a records printString.
	a do: [:dbf | Transcript cr;
				show: dbf currentRecordIndex printString;
				tab; show:  (dbf atFieldName: 'SHORT') printString;
				tab; show:  (dbf atFieldName: 'MEDIUM') printString;
				tab; show:  (dbf atFieldName: 'LONG') printString;
				tab; show:  (dbf atFieldName: 'NUM') printString;
				tab; show:  (dbf atFieldName: 'NUMDEC') printString].
	Transcript cr; show: 'Closing xBase test file and exiting ...'.
	a close.
	Transcript show: ' Done'.
	^a
]

{ #category : #filters }
XBaseFile >> addFilter: aBlock [ 
	"Append a new filter condition. Filter conditions are chained by a logical AND"

	filterArray isNil ifTrue: [^self setFilter: aBlock].
	filterArray addLast: aBlock
]

{ #category : #'accessing - editing' }
XBaseFile >> append [
	"append a new, blank record. Committed directly to fileStream"
	"Add the end-of-file tag to the fileStream, and update header info in the fileStream"

	self modificationTest.
	"go to the end of the file (to the eof flag I assume)"
	nRecords > 0 
		ifTrue: 
			[self gotoRecord: nRecords.
			fileStream skip: recordSize]
		ifFalse: [fileStream position: headerSize].
	"increment nRecords and currentRecordIndex"
	nRecords := nRecords + 1.
	self currentRecordIndex: nRecords.
	"make new record and commit it to the file stream"
	self blankRecord; saveRecord.
	self appendEndOfFileFlag.
	self updateHeaderInfo	"currently the only possible change in headerinfo is in <records>"
]

{ #category : #private }
XBaseFile >> appendEndOfFileFlag [
	"set the end of file flag after the last record"

	fileStream position: headerSize + ( nRecords * recordSize).
	^fileStream nextPut: 26
]

{ #category : #accessing }
XBaseFile >> atField: anInteger [ 
	"answer content of field at index anInteger in the current record"
	"assumes that <recordBytes> is already filled with the bytes of the current record"

	self deleted ifTrue: [^nil].
	^(readBlocks at: anInteger) value: self value: (recordBytes at: anInteger)
]

{ #category : #'accessing - editing' }
XBaseFile >> atField: anInteger put: fieldValue [ 
	" set value of field at index anInteger to fieldValue"
	"Not committed on fileStream until #saveRecord is sent"

	| old bytes |
	old := recordBytes at: anInteger.
	bytes := (writeBlocks at: anInteger) value: self value: fieldValue.
	old = bytes 	"#(10 20 30 40 50) = #(10 20 30 40 50) true "
		ifFalse: 
			[self modified: true.
			recordBytes at: anInteger put: bytes]
]

{ #category : #'accessing - by name' }
XBaseFile >> atFieldName: aFieldName [ 
	"answer the value of aFieldName in the current record <recordBytes>"

	| k |
	k := aFieldName asString asUppercase.
	^self atField: (fieldIndicesUC at: k ifAbsent: [^nil])
]

{ #category : #'accessing - by name' }
XBaseFile >> atFieldName: fieldName put: fieldValue [ 
	"set the value of aFieldName in the current record <recordBytes>"

	| k |
	k := fieldName asString asUppercase.
	^self atField: (fieldIndicesUC at: k ifAbsent: [^nil]) put: fieldValue
]

{ #category : #private }
XBaseFile >> baseUnformatNumberFromByteArray: aByteArray [ 
	"Convert aString into aNumber. For floating point values scan aString 
	for possible scientific notation"
	"scientific notation, e.g. '6.665804E+001'"
	"'6.665804E+001' -> '6.665804d001'"
	"Integer readFrom: '23.456' readStream 23"
	"'23.456' asNumber 23.456"
	"'23.45678912345' asNumber 23.45678912345"
	"withBlanksTrimmed in last line not required anymore (at least, spaces 
	are ignored)"
	| i exp digits sp num val sign char frac fsz expSign extra sz |

	char := aByteArray first.
	i := 1.
	sz := aByteArray size.
	sp := 32 "Character space charCode".
	digits := '0123456789' asByteArray.
	val := nil.
	num := 0.
	sign := (char = $- charCode) ifTrue: [-1] ifFalse: [1].
	[i <= sz and: [ char = sp or: [(val := digits indexOf: char) > 0]]] whileTrue: [
		val isNil
			ifFalse: [
				num := (num * 10) + (val - 1).
				val := nil.
				].
		i := i + 1.
		i <= sz ifTrue: [char := aByteArray at: i].
		].
	i > sz ifTrue: [^num * sign].
	fsz := 0.
	char = 46 "$. charCode" ifTrue: ["<integer>.<fraction>"
		char := aByteArray at: (i := i + 1).
		val := nil.
		frac := 0.
		[i <= sz and: [ char = sp or: [(val := digits indexOf: char) > 0]]] whileTrue: [
			val isNil
				ifFalse: [
					frac := (frac * 10) + (val - 1).
					val := nil.
					fsz := fsz + 1.
					].
			i := i + 1.
			i <= sz ifTrue: [char := aByteArray at: i].
			].
		fsz > 0 ifTrue: [num := num asFloat + (frac asFloat / (10 raisedTo: fsz))].
		].
	i > sz ifTrue: [
		(fsz > 0 and: [num = 0.0 and: [sign = -1]]) ifTrue: [^Float negativeZero].
		^num * sign
		].
	exp := 'Ee' asByteArray.
	val := nil.
	[i <= sz and: [char = sp]] whileTrue: [char := aByteArray at: (i := i + 1)].
	(exp includes: char) ifTrue: ["exponent"
		char := aByteArray at: (i := i + 1).
		expSign := 1.
		exp := 0.
		extra := ' +-' asByteArray.
		[i <= sz and: [ (extra includes: char) or: [(val := digits indexOf: char) > 0]]] whileTrue: [
			val isNil
				ifTrue: [
					(char = $- charCode) ifTrue: [expSign := -1.].
				] ifFalse: [
					exp := (exp * 10) + (val - 1).
					val := nil.
					].
			i := i + 1.
			i <= sz ifTrue: [char := aByteArray at: i].
			].
		exp > 0 ifTrue: [
			num := num * (10 raisedTo: (exp * expSign)).
			].
		].
	(fsz > 0 and: [num = 0.0 and: [sign = -1]]) ifTrue: [^Float negativeZero].
	^num * sign

]

{ #category : #private }
XBaseFile >> blankRecord [
	"current record is a new record with blank contents and the delete-flag set to false"

	"note that contents are not yet committed to the fileStream (requires a #saveRecord)"

	recordBytes := Array new: nFields.
	1 to: nFields
		do: [:i | recordBytes at: i put: ((writeBlocks at: i) value: self value: nil)].
	self deleted: false
]

{ #category : #testing }
XBaseFile >> bof [
	"test a beginning of file condition"

	^bof
]

{ #category : #private }
XBaseFile >> bytes2Num: aByteArray [ 
	"converts hex num in aByteArray into an integer"

	| aNum ix |
	aNum := 0.
	ix := 1.
	aByteArray do: 
			[:a | 
			aNum := aNum + (a * ix).
			ix := ix * 256].
	^aNum
]

{ #category : #'open/close' }
XBaseFile >> close [
	" Close XBaseFile flushing last updates and release object"

	self modificationTest.			"current record is saved"
	fileStream isNil ifFalse: [fileStream close].
	fileStream := nil
]

{ #category : #accessing }
XBaseFile >> contents [
	"dump all data in anArray excluding header!"
	"deleted records are included as empty Arrays (all nil)"
	"2009-08-13 CBC - Enhanced method to use new 'fast' #recordDataFast."

	| contents |
	self modificationTest.
	contents := Array new: self records.
	fileStream position: headerSize.
	1 to: nRecords
		do: 
			[:i | 
			contents at: i put: self recordDataFast].
	self currentRecordIndex: nRecords.
	^contents
]

{ #category : #accessing }
XBaseFile >> contentsAsCSVNamed: csvFileName [
	"deleted records are NOT included"
	| csv incr x |

	incr := 1000 / nRecords.
	self modificationTest.
	fileStream position: headerSize.
	x := 0.
	csv := FileStream newFileNamed: csvFileName.
	[ [ : job |
		job title:  'Converting DBF to CSV (', csvFileName, '), total ', nRecords asString, ' records...'.
		csv nextPutAll: self fields asCSVLine; cr.
		1 to: nRecords do: [ : i | 
			[ csv nextPutAll: self recordDataFast asCSVLine; cr ] on: XBaseDeletedRecord do: [].
				x := x + 1.
				x = 1000 ifTrue: [
					x := 0.
					job progress: incr ] ] ] asJob run 
	] ensure: [csv close].
	self currentRecordIndex: nRecords.

]

{ #category : #accessing }
XBaseFile >> contentsAtField: aKey [ 
	"dump data (all records, including deleted) found at field aKey (String) in anArray (=column)"

	"aKey itself is not included in anArray"

	| contents index |
	index := fieldIndicesUC at: aKey ifAbsent: [^#()].
	self modificationTest.
	contents := Array new: self records.
	1 to: nRecords
		do: 
			[:i | 
			fileStream position: headerSize + ((i - 1) * recordSize).
			self currentRecordIndex: i.
			self getRecord.
			contents at: i put: (self atField: index)].
	^contents
]

{ #category : #accessing }
XBaseFile >> contentsAtFields: aCollection [ 
	"dump data (all records, including deleted) for all fieldnames in aCollection in Arrays"

	"to avoid confusion between upper- and lowercase field names, fields in aCollection and fields 
	in the DBF are compared after converting (BOTH!) to uppercase"

	| contents indices |
	indices := (aCollection 
				collect: [:each | fieldIndicesUC at: each asUppercase ifAbsent: [^self halt]]) 
					asArray.
	self modificationTest.
	contents := Array new: self records.
	1 to: nRecords
		do: 
			[:i | 
			fileStream position: headerSize + ((i - 1) * recordSize).
			self currentRecordIndex: i.
			self getRecord.
			contents at: i put: (indices collect: [:index | self atField: index])].
	^contents
]

{ #category : #accessing }
XBaseFile >> contentsWithFields [
	"dump all data in anArray including the field labels (as a last record)"
	"deleted records are included as empty Arrays (all nil)"
	"2009-08-13 CBC - Enhanced method to use new 'fast' #recordDataFast."

	| contents |
	self modificationTest.
	contents := Array new: self records + 1.
	fileStream position: headerSize.
	1 to: nRecords
		do: 
			[:i | 
			contents at: i put: self recordDataFast].
	self currentRecordIndex: nRecords.
	contents at: self records + 1 put: self fields.
	^contents
]

{ #category : #private }
XBaseFile >> create: fDictionary [ 
	"create a new XBaseFile (with open file stream), with fields defined by fDictionary, and 0 records"
	| pos |
	fileStream := (StandardFileStream newFileNamed: fileName) binary.
	lastUpdate := Date today.
	nRecords := 0.
	currentRecordIndex := 0.
	self modified: false.
	self deleted: false.
	pos := 1.
	fields := OrderedCollection new.
	fieldIndices := Dictionary new.
	fieldIndicesUC := Dictionary new.
	fieldFormats := OrderedCollection new.
	readBlocks := OrderedCollection new.
	writeBlocks := OrderedCollection new.
	fDictionary
		do: [:a | 
			| name format | 
			name := a first asString asUppercase.
			name := name
						copyFrom: 1
						to: (10 min: name size).
			"10 bytes for the name (11th byte should be 16r00=0)"
			fields addLast: name.
			format := a copyFrom: 2 to: a size.
			format at: 4 put: pos.
			"fill in the missing offset value (at pos=0 we have the deleted 
			flag) "
			fieldIndices at: name put: fields size.
			fieldIndicesUC at: name asUppercase put: fields size.
			fieldFormats addLast: format.
			readBlocks
				addLast: (self
						readBlockFor: (format at: 1)
						dec: (format at: 3)).
			writeBlocks
				addLast: (self
						writeBlockFor: (format at: 1)
						dec: (format at: 3)
						length: (format at: 2)).
			pos := pos
						+ (format at: 2)].
	fields := fields asArray.
	nFields := fields size.
	recordSize := pos.
	headerSize := 34 + (fields size * 32).
	self saveHeaderInfo
]

{ #category : #private }
XBaseFile >> currentRecordIndex [
	"answer the index of the current record"

	^currentRecordIndex
]

{ #category : #private }
XBaseFile >> currentRecordIndex: anInteger [
	"keep the index of the current record in <currentRecordIndex>"

	currentRecordIndex := anInteger
]

{ #category : #'accessing - editing' }
XBaseFile >> delete [
	"mark as deleted current record. Not committed until #saveRecord is sent"

	self deleted 
		ifFalse: 
			[self deleted: true.
			self modified: true]
]

{ #category : #testing }
XBaseFile >> deleted [
	"true if the current record has the deleted-tag"
	"deleted is set with #getRecord (read from fileStream). If the record is deleted (#delete) or restored (#restore), it is changed using #deleted: aBoolean. 
	When committed to fileStream, the value of <deleted> is used as the deleted tag"

	^deleted
]

{ #category : #testing }
XBaseFile >> deleted: aBoolean [
	"set the deleted-tag for the current record (not yet committed to the fileStream though!)"

	deleted := aBoolean
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> deletedFlagRecord: anInteger [ 
	"answer the value of the deleted flag for record anInteger"
	"16r2A (42) deleted; 16r20 (32) valid"

	fileStream position: headerSize + ((anInteger - 1) * recordSize).
	^fileStream next
]

{ #category : #iterating }
XBaseFile >> do: aBlock [ 
	"iterate over all records. Evaluate aBlock with self as the argument, each time currentRecord points to a new record"

	self goTop.
	[self eof or: [self bof]] whileFalse: 
			[aBlock value: self.
			self skip]
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> endOfFileFlag [
	"answer the last byte of the file, the end of file flag 16r1A (26)"

	fileStream position: headerSize + ( nRecords * recordSize).
	^fileStream next
]

{ #category : #testing }
XBaseFile >> eof [
	"test an end of file condition"

	^eof
]

{ #category : #filters }
XBaseFile >> evaluateFilters [
	"answer true if the evaluated value should be trapped by the filter, and the record skipped"

	| answ |
	answ := true.
	filterArray do: [:a | answ := answ and: [a value: self]].	"logically AND evaluations of all elements"
	^answ not
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldDec: fieldName [ 
	"returns field decimal positions for field named fieldName (string or 
	symbol, case-insensitive)"
	^ (fieldFormats
		at: (fieldIndicesUC
				at: fieldName asString asUppercase
				ifAbsent: [^ nil]))
		at: 3
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldInfos: fieldName [ 
	"returns an array defining the format of field named fieldName (string or symbol, case insensitive): 
	1 = field type; 2 = field length; 3 = field decimal positions; 4 = field offset inside record.  
	Method returns nil if fieldName is not in file"
	^ fieldFormats
		at: (fieldIndicesUC
				at: fieldName asString asUppercase
				ifAbsent: [^ nil])
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldInfosDictionary [
	"returns a Dictionary with the field info. Key is the field name, value is an array with field type, field length, field decimal positions and field offset inside record"

	| dict |
	dict := Dictionary new.
	1 to: fields size
		do: [:i | dict at: (fields at: i) put: (fieldFormats at: i)].
	^dict
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldLen: fieldName [ 
	"returns field length for field named fieldName (string or symbol, case 
	insensitive). Method returns nil if fieldName is not in file"
	^ (fieldFormats
		at: (fieldIndicesUC
				at: fieldName asString asUppercase
				ifAbsent: [^ nil]))
		at: 2
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldOffset: fieldName [ 
	"returns the offset of the field in the record. Method returns nil if fieldName is not in file"
	^ (fieldFormats
		at: (fieldIndicesUC
				at: fieldName asString asUppercase
				ifAbsent: [^ nil]))
		at: 4
]

{ #category : #'accessing - field format' }
XBaseFile >> fieldType: fieldName [ 
	"returns aCharacter describing field type of field named fieldName (string or symbol, case insensitive). $C = Character field, $N = Numeric field, $L = logical field, $D = date field, $F = Float. Returns nil if fieldName is not in file"

	^(fieldFormats at: (fieldIndicesUC at: fieldName asString asUppercase ifAbsent: [^nil])) at: 1
]

{ #category : #accessing }
XBaseFile >> fields [
	"answer anArray with field labels (all uppercase) "
	^ fields
]

{ #category : #private }
XBaseFile >> formatBooleanFieldValue: v [ 
	"convert aBoolean into the appropriate String"
	" 'F' asString = 'F' true "
	" 'F' asByteArray #[70]; 'T' asByteArray #[84] "

	| answ |
	v isNil ifTrue: [^'F'].
	answ := v ifTrue: ['T'] ifFalse: ['F'].
	^answ
]

{ #category : #private }
XBaseFile >> formatDateFieldValue: v [ 
	"convert aDate into the appropriate String"
	| answ tmp |
	v isNil 
		ifTrue: 
			[^self formatDateFieldValue: (Date 
						year: 1
						month: 1
						day: 1)].
	answ := v year printString.
	tmp := '0' , v monthIndex printString.
	tmp := tmp copyFrom: tmp size - 1 to: tmp size.
	answ := answ , tmp.
	tmp := '0' , v day printString.
	tmp := tmp copyFrom: tmp size - 1 to: tmp size.
	answ := answ , tmp.
	^answ
]

{ #category : #private }
XBaseFile >> formatNumberFieldLength: len decimalC: d value: v [ 
	"convert a Number into the appropriate ByteString"
	"decimalPart is rounded and takes up always d characters"

	"when length of the ByteString exceeds len, throw an error. 
	This will only occur when the integerPart of v is too large to fit
	in len - d - 1(dot) - 1(if negative). Solution: increase len"

	"	
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: 1.23456 '1.23  ' 
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: -1.23995678 '-1.24 '
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: 1.2 '1.20  '
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: 123.2  '123.20'
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: 1234  error
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: 1234.2 error
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: -12.2  '-12.20' 
	XBaseFile new formatNumberFieldLength: 6 decimalC: 2 value: -123.2 error

	XBaseFile new formatNumberFieldLength: 24 decimalC: 7 value: 51.0999478 -> '51.0999478              '
	"

	| space stream value result integerPart decimalPart |
	space := Character space.
	v isNil ifTrue: [^String new: len withAll: space].
	stream := WriteStream on: (String new: len). 
	d > 0 
		ifTrue: 
			[ | mul |
			integerPart := v truncated.
			"decimalPart := (v fractionPart abs * (10.0 raisedToInteger: d)) rounded. -- wont work for 0.0099123"
			"better just do a rounding-off and use the simple printString of the fractionPart"
			mul := 10.0 raisedToInteger: d.	"10.0 raisedToInteger: 7 -> 1.0e7"
			decimalPart := (v fractionPart abs * mul) rounded asFloat / mul.
			integerPart printOn: stream.
			stream nextPut: $..
			decimalPart isZero 
				ifTrue: [d timesRepeat: [stream nextPut: $0] "fill the whole decimal part"]
				ifFalse: [| str | str := ReadStream on: decimalPart printString. str upTo: $.. d timesRepeat: [str atEnd ifFalse: [stream nextPut: str next]]]]
		ifFalse: 
			[value := v asInteger.
			value printOn: stream].
	result := stream contents.
	result size < len 
		ifTrue: [len - result size timesRepeat: [stream nextPut: space]]
		ifFalse: 
			[result size > len 
				ifTrue: 
					[self error: v printString , ' does not fit in field!'.
					^String new: len withAll: space]].
	^stream contents
]

{ #category : #private }
XBaseFile >> formatNumberFieldLengthOldVersion: len decimalC: d value: v [ 
	"convert a Number into the appropriate ByteString"
	"old version, not strict enough (when the decimal positions are not used all, bigger integerParts are possible)"
	"	
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 1.23456 '1.23  '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 1.23999 '1.24  '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: -1.2399  '-1.24 '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: -1.23456 '-1.23 '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 1234 '1234.0' -> should be an error
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: -123  '-123.0' -> should be an error
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 1.2 '1.2   '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 123.2 '123.2 '
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 1234.2 '1234.2' -> should be an error
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 123456.23  error
	XBaseFile new formatNumberFieldLengthOldVersion: 6 decimalC: 2 value: 234567  error
	"

	| space stream value result |
	space := Character space.
	v isNil ifTrue: [^String new: len withAll: space].
	stream := WriteStream on: (String new: len).
	d > 0 
		ifFalse: 
			[value := v asInteger.
			value printOn: stream]
		ifTrue: 
			[value := v asFloat roundTo: (1 / (10 raisedToInteger: d)) asFloat.
			value printOn: stream].
	result := stream contents.
	result size < len 
		ifTrue: [len - result size timesRepeat: [stream nextPut: space]]
		ifFalse: [result size > len ifTrue: [self error: (v printString , ' does not fit in field!')]].
	^stream contents
]

{ #category : #private }
XBaseFile >> formatStringFieldLength: len value: v [ 
	"convert a String into the appropriate ByteString"
	| answ space |
	space := Character space.
	v isNil ifTrue: [^ String new: len withAll: space].
	answ := v , (String new: len withAll: space) copyFrom: 1 to: len.
	^ answ
]

{ #category : #private }
XBaseFile >> getDBFInfos [
	"get all infos about open DBF file"

	self
		getHeaderInfo;
		getFieldsInfos
]

{ #category : #private }
XBaseFile >> getFieldsInfos [
	"extract field formats from the file stream and move these into a fieldsInfos dictionary"
	"keep also a fields array, with just the names in the correct order"

	| pos name type len dec fpos |
	fields := OrderedCollection new.
	pos := 32.
	fieldIndices := Dictionary new.
	fieldIndicesUC := Dictionary new.
	fieldFormats := OrderedCollection new.
	readBlocks := OrderedCollection new.
	writeBlocks := OrderedCollection new.
	fpos := 1.
	[pos < (headerSize - 2)]
		whileTrue: 
			[fileStream position: pos.
			name := (fileStream upTo: 0) "asByteString in VW" asString.
			fileStream position: pos + 11.
			type := fileStream next asCharacter.
			fileStream skip: 4.
			dec := 0.
			type == $C
				ifTrue: [len := self bytes2Num: (fileStream next: 2)]
				ifFalse: 
					[len := fileStream next.
					dec := fileStream next].
			fields addLast: name.
			fieldIndices at: name put: fields size.
			fieldIndicesUC at: name asUppercase put: fields size.
			fieldFormats addLast: (Array with: type with: len with: dec with: fpos).
			readBlocks addLast: (self readBlockFor: type dec: dec).
			writeBlocks addLast: (self writeBlockFor: type dec: dec length: len).
			fpos := fpos + len.
			pos := pos + 32].
	fields := fields asArray.
	nFields := fields size
]

{ #category : #private }
XBaseFile >> getHeaderInfo [
	"extract header information and move these data to instance variables"

	| d m y |
	fileStream position: 1.
	y := fileStream next.
	m := fileStream next.
	d := fileStream next.
	y < 1900 ifTrue: [y := 1900 + y].
"	lastUpdate := Date newDay: d monthNumber: m year: y."
	lastUpdate := Date year: y month: m day: d.
	nRecords := self bytes2Num: (fileStream next: 4).
	headerSize := self bytes2Num: (fileStream next: 2).
	recordSize := self bytes2Num: (fileStream next: 2)
]

{ #category : #private }
XBaseFile >> getRecord [
	"extract current record contents and move these to fieldsContents values"
	"requires that fileStream is already positioned at the beginning of the record"
	"2009-08-12 CBC - Read the whole record in, then parse in memory."
	| buffer |

	buffer := (fileStream next: recordSize) readStream.
	recordBytes := Array new: nFields.
	self deleted: buffer next = 42.	"first Byte is deleted-flag. 16r20 32 for valid, and 16r2A 42 for deleted"
	1 to: nFields
		do: [:i | recordBytes at: i put: (buffer next: ((fieldFormats at: i) at: 2))]
]

{ #category : #positioning }
XBaseFile >> goBottom [
	"set last record in file as current record. Deleted and Filter settings are accounted for"

	self
		goto: nRecords;
		skip: 0 direction: -1
]

{ #category : #positioning }
XBaseFile >> goTop [
	"set first record in file as current record. Deleted and Filter settings are accounted for"

	self
		goto: 1;
		skip: 0 direction: 1
]

{ #category : #positioning }
XBaseFile >> goto: rNumber [ 
	"position file on record number rNumber"

	"add a blank record when rNumber exceeds <records>. Do not commit anything to the fileStream yet (except for the previously modified record)"

	| recordNumber |
	eof := false.
	bof := false.
	self modificationTest.
	rNumber < 1 
		ifTrue: 
			[recordNumber := 1.
			bof := true]
		ifFalse: [recordNumber := rNumber].
	recordNumber <= nRecords 
		ifTrue: 
			[self gotoRecord: recordNumber.
			self getRecord]
		ifFalse: 
			[self currentRecordIndex: nRecords + 1. "increase record count by 1"
			eof := true.
			self blankRecord	"a blank record becomes the current record"]
]

{ #category : #private }
XBaseFile >> gotoRecord: recordNumber [ 
	"position currentRecord to recordNumber"

	(recordNumber <= nRecords and: [recordNumber > 0]) 
		ifFalse: [^self error: 'Record number outside file bounds'].
	fileStream position: headerSize + ((recordNumber - 1) * recordSize).
	self currentRecordIndex: recordNumber
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> headerSize [
	fileStream position: 8.
	^self bytes2Num: (fileStream next: 2)
]

{ #category : #testing }
XBaseFile >> isDBFFile [
	"tests if the open file is a .DBF file (signature byte=03)"

	fileStream position: 0.
	^fileStream next asInteger = 3
]

{ #category : #private }
XBaseFile >> memoryCreate: fDictionary [ 
	"create a new XBaseFile object with bytes in an in-memory stream, with fields defined by fDictionary, and 0 records"
	| pos |
	fileStream := ReadWriteStream on: (ByteArray new: 1000). 
	lastUpdate := Date today.
	nRecords := 0.
	currentRecordIndex := 0.
	self modified: false.
	self deleted: false.
	pos := 1.
	fields := OrderedCollection new.
	fieldIndices := Dictionary new.
	fieldIndicesUC := Dictionary new.
	fieldFormats := OrderedCollection new.
	readBlocks := OrderedCollection new.
	writeBlocks := OrderedCollection new.
	fDictionary
		do: [:a | 
			| name format | 
			name := a first asString asUppercase.
			name := name
						copyFrom: 1
						to: (10 min: name size).
			"10 bytes for the name (11th byte should be 16r00=0)"
			fields addLast: name.
			format := a copyFrom: 2 to: a size.
			format at: 4 put: pos.
			"fill in the missing offset value (at pos=0 we have the deleted 
			flag) "
			fieldIndices at: name put: fields size.
			fieldIndicesUC at: name asUppercase put: fields size.
			fieldFormats addLast: format.
			readBlocks
				addLast: (self
						readBlockFor: (format at: 1)
						dec: (format at: 3)).
			writeBlocks
				addLast: (self
						writeBlockFor: (format at: 1)
						dec: (format at: 3)
						length: (format at: 2)).
			pos := pos
						+ (format at: 2)].
	fields := fields asArray.
	nFields := fields size.
	recordSize := pos.
	headerSize := 34 + (fields size * 32).
	self saveHeaderInfo
]

{ #category : #private }
XBaseFile >> modificationTest [
	"if changed, save the current record"
	self modified ifTrue: [self saveRecord].
]

{ #category : #testing }
XBaseFile >> modified [
	"true if the current record has been changed"

	^modified
]

{ #category : #testing }
XBaseFile >> modified: aBoolean [
	"set the modified tag"

	^modified := aBoolean
]

{ #category : #filters }
XBaseFile >> noFilter [
	"remove any filter setting for file"

	filterArray := nil
]

{ #category : #private }
XBaseFile >> num2Bytes: aNum size: aSize [ 
	"converts aNum hex num to aByteArray"

	| tmp answ |
	answ := ByteArray new: aSize withAll: 32.
	tmp := aNum.
	1 to: aSize
		do: 
			[:ix | 
			answ at: ix put: ("Character value:" tmp \\ 256).
			tmp := tmp // 256].
	^answ
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> numberOfRecords [
	fileStream position: 4.
	^self bytes2Num: (fileStream next: 4)
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> offsetRecord: anInteger [ 
	"answer the offset (position) where record anInteger starts"

	^headerSize + ((anInteger - 1) * recordSize)
]

{ #category : #'open/close' }
XBaseFile >> open [
	"Open an existing .DBF file in binary mode"
	"This methods is called by class methods #new: and  
	#new:fields:. May be called directly to reopen a closed file"
	fileStream := fileName asFileReference binaryReadStream.
	self isDBFFile
		ifTrue: [self modified: false.
			self getDBFInfos.
			self goto: 1.
			^ self]
		ifFalse: [fileStream close.
			^ self error: fileName , ': is not a .DBF file']
]

{ #category : #debugging }
XBaseFile >> printTranscript [
	"print all records on the Transcript"

	self goTop.
	Transcript cr.
	fields do: [:each | Transcript show: each] separatedBy: [Transcript tab].
	[eof or: [bof]] whileFalse: 
			[Transcript cr.
			fields do: [:each | Transcript show: (self atFieldName: each) printString]
				separatedBy: [Transcript tab].
			self skip]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockFor: aSymbol dec: dec [

	aSymbol == $N ifTrue: [^self readBlockForNumber].
	aSymbol == $C ifTrue: [^self readBlockForString].
	aSymbol == $L ifTrue: [^self readBlockForBoolean].
	aSymbol == $D ifTrue: [^self readBlockForDate].
	aSymbol == $F ifTrue: [^self readBlockForFloatDec: dec].
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForBoolean [

	^[:dbf :bytes | dbf unformatBooleanFromBytes: bytes]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForDate [

	^[:dbf :bytes | dbf unformatDateFromString: bytes "asByteString in VW" asString]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForFloat [
	^ [:dbf :bytes | dbf unformatFloatFromByteArray: bytes]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForFloatDec: anInteger [ 
	^ [:dbf :bytes | dbf unformatFloatFromByteArray: bytes dec: anInteger]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForNumber [

	^[:dbf :bytes | dbf unformatNumberFromByteArray: bytes]
]

{ #category : #'block contexts' }
XBaseFile >> readBlockForString [
	^ [:dbf :bytes | dbf unformatStringFromString: bytes asString
	"asByteString"]
]

{ #category : #accessing }
XBaseFile >> recordData [
	"answer anArray with all the data in the current record (as Smalltalk objects, not bytes)"

	| data |
	data := Array new: nFields.
	self deleted ifTrue: [^data].
	1 to: nFields
		do: 
			[:i | 
			data at: i put: ((readBlocks at: i) value: self value: (recordBytes at: i))].
	^data
]

{ #category : #accessing }
XBaseFile >> recordDataFast [
	"answer anArray with all the data in the current record (as Smalltalk objects, not bytes)"
	"2009-08-12 CBC - Super fast is to bypass getRecord and read/convert here, without the interim byte values.  This should
		only be called if getRecord hasn't been called first, but all of the requirements of getReocrd is met.
		Read the whole record in, then parse in memory."
	| buffer data |

	buffer := (fileStream next: recordSize) readStream.
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

{ #category : #'accessing - asynchronous' }
XBaseFile >> recordLength [
	"the length of each record, in bytes"

	fileStream position: 10.
	^self bytes2Num: (fileStream next: 2)
]

{ #category : #accessing }
XBaseFile >> records [
	"return the number of records in file (including records with deleted-tag)"

	^nRecords
]

{ #category : #'accessing - editing' }
XBaseFile >> restore [
	"unmark as deleted current record. Not committed until #saveRecord is sent"

	self deleted 
		ifTrue: 
			[self deleted: false.
			self modified: true]
]

{ #category : #iterating }
XBaseFile >> reverseDo: aBlock [ 
	"iterate backwards over all records. Evaluate aBlock with self as the argument, each time currentRecord points to a new record"

	self goBottom.
	[self eof or: [self bof]] whileFalse: 
			[aBlock value: self.
			self skip: -1]
]

{ #category : #private }
XBaseFile >> saveFieldsInfos [
	"commit the field formats to the fileStream"
	"on a real file stream this works ok; when trying to do the same on an internal stream, #position: fails"
	| pos |
	pos := 32.
	fileStream position: 32.
	fieldFormats
		with: fields
		do: [:info :name | 
			fileStream position: pos.
			(ByteArray new: 11 withAll: 0)
				do: [:byte | fileStream nextPut: byte].
			"erase the previous contents"
			fileStream position: pos.
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

{ #category : #private }
XBaseFile >> saveHeaderInfo [
	"save .DBF file header info's"

	fileStream
		position: 0;
		nextNumber: 1 put: 3;
		nextNumber: 1 put: lastUpdate year - 1900;
		nextNumber: 1 put: lastUpdate monthIndex;
		nextNumber: 1 put: lastUpdate dayOfMonth ;
		nextPutAll: (self num2Bytes: nRecords size: 4);
		nextPutAll: (self num2Bytes: headerSize size: 2);
		nextPutAll: (self num2Bytes: recordSize size: 2).
	self saveFieldsInfos.
	fileStream nextNumber: 1 put: 13.			"Terminator (of the header structure) 16r0D = 13"
	fileStream nextNumber: 1 put: 0.				"insert something, otherwise completely empty"
	fileStream nextNumber: 1 put: 26				"End of file flag 16r1A = 26"
]

{ #category : #private }
XBaseFile >> saveRecord [
	"commit the current record contents to the fileStream (overwrite 
	previous contents)"
	"#saveRecord is automatically performed when moving to another record 
	(#goto:) and the current record has been modified. 
	see #append, #close and #goto:"
	self gotoRecord: currentRecordIndex.
	"position fileStream at offset record"
	self deleted
		ifTrue: [fileStream nextPut: 42]
		ifFalse: [fileStream nextPut: 32].
	"the deleted record flag"
	recordBytes
		do: [:fieldBytes | fieldBytes
				do: [:byte | fileStream nextPut: byte]].
	"pump record bytes into the stream"
	self modified: false
]

{ #category : #filters }
XBaseFile >> setFilter: aBlock [ 
	"set a new filter condition. Any preceding filter condition is lost. aBlock is a one-argument Block expecting the receiver as its argument"

	filterArray := OrderedCollection with: aBlock
]

{ #category : #private }
XBaseFile >> setName: aString [ 
	"Set the .DBF file name to aString"

	| ext |
	ext := ''.
	(aString includes: $.) ifFalse: [ext := '.DBF'].
	fileName := aString , ext
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> signature [
	"answer the first byte"

	fileStream position: 0.
	^fileStream next
]

{ #category : #positioning }
XBaseFile >> skip [
	"set next record in file as current record. Deleted and Filter settings are accounted for"

	^self skip: 1 direction: 1
]

{ #category : #positioning }
XBaseFile >> skip: aNumber [ 
	"jump to next aNumber record. Jump maybe forward (aNumber > 0) or backward (aNumber <0). Deleted and Filter settings are accounted for."

	self skip: aNumber direction: aNumber abs / aNumber
]

{ #category : #positioning }
XBaseFile >> skip: aNumber direction: ofs [ 
	"skip aNumber of positions (records) in the direction ofs (+1 or -1)"
	"halt when bof or eof is encountered; deleted or filtered records do not count, I think"

	self goto: currentRecordIndex + aNumber.
	
	[(((filterArray isNil not and: [self evaluateFilters]) or: [deleted]) 
		and: [eof not]) and: [bof not]] 
			whileTrue: [self goto: currentRecordIndex + ofs]
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> testHeaderTerminator [
	"check whether the Terminator is present"

	fileStream position: self headerSize - 1.
	^fileStream next = 16r0D "13"
]

{ #category : #'accessing - asynchronous' }
XBaseFile >> testNumberOfAttributes [
	"derive the number of attributes from the space used by the header (32 bytes per attribute)"

	^fields size = (self headerSize - 1 - 32 / 32) "1 = the terminator; 32 = the fields in the header before the attribute fields"
]

{ #category : #private }
XBaseFile >> unformatBooleanFromBytes: aByteArray [
	"Logic -> Boolean: $T asInteger = 84 and $F asInteger = 70"

	^aByteArray first = 84
]

{ #category : #private }
XBaseFile >> unformatDateFromString: aString [ 
	"Convert aString into aDate"

	| rStream y m dy |
	rStream := ReadStream 
				on: aString
				from: 1
				to: 8.
	y := (rStream next: 4) asInteger.
	m := (rStream next: 2) asInteger.
	dy := (rStream next: 2) asInteger.
	^Date 
		year: y
		month: m
		day: dy
]

{ #category : #private }
XBaseFile >> unformatFloatFromByteArray: aByteArray [
	"Convert aString into aNumber. For floating point values scan aString for possible scientific notation"
	^self baseUnformatNumberFromByteArray: aByteArray
]

{ #category : #private }
XBaseFile >> unformatFloatFromByteArray: aByteArray dec: dc [
	"Convert aString into aFloating point; enforce dc as number of decimals"

	^(self unformatFloatFromByteArray: aByteArray) 
		roundTo: (1 / (10 raisedToInteger: dc) ) asFloat
]

{ #category : #private }
XBaseFile >> unformatFloatFromString: aString [ 
	"Convert aString into aNumber. For floating point values scan aString for possible scientific notation"
	"scientific notation, e.g. '6.665804E+001' "
	" '6.665804E+001' -> '6.665804e001' "

	"Integer readFrom: '23.456' readStream 23"
	"'23.456' asNumber 23.456"
	"'23.45678912345' asNumber 23.45678912345"
	"withBlanksTrimmed not required anymore in last line (spaces are filtered out)"

	| rStream wStream n sp |
	rStream := aString readStream.
	wStream := WriteStream on: (String new: aString size).
	sp := Character space.
	[rStream atEnd] whileFalse: 
			[n := rStream next.
			(n == $E or: [n == $e]) 
				ifTrue: [wStream nextPut: $e]
				ifFalse: [n == $+ ifFalse: [n == sp ifFalse: [wStream nextPut: n]]]].
	^wStream contents asNumber
]

{ #category : #private }
XBaseFile >> unformatFloatFromString: aString dec: dc [
	"Convert aString into aFloating point; enforce dc as number of decimals"

	^(self unformatFloatFromString: aString) 
		roundTo: (1 / (10 raisedToInteger: dc) ) asFloat
]

{ #category : #private }
XBaseFile >> unformatNumberDecimals: dc fromByteArray: aByteArray [
	"Convert aString into aFloating point; enforce dc as number of decimals"

	^(self unformatFloatFromByteArray: aByteArray) 
		roundTo: (1 / (10 raisedToInteger: dc) ) asFloat
]

{ #category : #private }
XBaseFile >> unformatNumberDecimals: dc fromString: aString [ 
	"Convert aString into aFloating point; enforce dc as number of decimals"

	^(self unformatFloatFromString: aString) 
		roundTo: (1 / (10 raisedToInteger: dc) ) asFloat
]

{ #category : #private }
XBaseFile >> unformatNumberFromByteArray: aByteArray [ 
	"Convert aString into aNumber. For floating point values scan aString 
	for possible scientific notation"

	aByteArray first == "$* charCode" 42 ifTrue: [^nil]. "or byte = 42"
	^self baseUnformatNumberFromByteArray: aByteArray
]

{ #category : #private }
XBaseFile >> unformatNumberFromString: aString [ 
	"Convert aString into aNumber. For floating point values scan aString 
	for possible scientific notation"
	"scientific notation, e.g. '6.665804E+001'"
	"'6.665804E+001' -> '6.665804d001'"
	"Integer readFrom: '23.456' readStream 23"
	"'23.456' asNumber 23.456"
	"'23.45678912345' asNumber 23.45678912345"
	"withBlanksTrimmed in last line not required anymore (at least, spaces 
	are ignored)"
	| rStream wStream n sp |
	aString first == $* ifTrue: [^nil]. "or byte = 42"
	rStream := aString readStream.
	wStream := WriteStream
				on: (String new: aString size).
	sp := Character space.
	[rStream atEnd]
		whileFalse: [n := rStream next.
			(n == $E
					or: [n == $e])
				ifTrue: [wStream nextPut: $e]
				ifFalse: [n == $+
						ifFalse: [n == sp
								ifFalse: [wStream nextPut: n]]]].
	^ wStream contents asNumber
]

{ #category : #private }
XBaseFile >> unformatStringFromString: aString [ 
	"aString contains the data string; just remove trailing spaces"

	| space i |
	space := Character space.
	aString last == space ifFalse: [^aString].
	i := aString size.
	[i > 0 and: [(aString at: i) == space]] whileTrue: [i := i - 1].
	^aString copyFrom: 1 to: i
]

{ #category : #private }
XBaseFile >> updateHeaderInfo [
	"currently only the number of records may have changed (increased through #append)"

	fileStream
		position: 4;
		nextPutAll: (self num2Bytes: nRecords size: 4)
]

{ #category : #testing }
XBaseFile >> version [
	"current version of XBase"

	^ 'XBaseFile ReaderWriter by Hans Baveco (Hans.Baveco@wur.NL). A thorough rewrite of Antonio d''Avino (andavino@tin.it) Squeak XBaseFile'
]

{ #category : #'block contexts' }
XBaseFile >> writeBlockFor: aSymbol dec: dec length: len [

	aSymbol == $N ifTrue: [^self writeBlockForNumberDec: dec length: len].
	aSymbol == $C ifTrue: [^self writeBlockForStringLength: len].
	aSymbol == $L ifTrue: [^self writeBlockForBoolean].
	aSymbol == $D ifTrue: [^self writeBlockForDate].
	aSymbol == $F ifTrue: [^self  writeBlockForNumberDec: dec length: len]
]

{ #category : #'block contexts' }
XBaseFile >> writeBlockForBoolean [
"	^ [:dbf :val | (dbf formatBooleanFieldValue: val) asByteString] for VW"
		
	^ [:dbf :val | ByteArray withAll: (dbf formatBooleanFieldValue: val)] 
]

{ #category : #'block contexts' }
XBaseFile >> writeBlockForDate [
"	^ [:dbf :val | (dbf formatDateFieldValue: val) asByteString] for VW"
	^ [:dbf :val | ByteArray withAll: (dbf formatDateFieldValue: val)]
]

{ #category : #'block contexts' }
XBaseFile >> writeBlockForNumberDec: d length: len [ 
"	^ [:dbf :val | (dbf formatNumberFieldLength: len decimalC: d value: val) asByteString] for VW"
	^ [:dbf :val | ByteArray withAll: (dbf formatNumberFieldLength: len decimalC: d value: val)]
]

{ #category : #'block contexts' }
XBaseFile >> writeBlockForStringLength: len [ 
"	^ [:dbf :val | (dbf formatStringFieldLength: len value: val) asByteString] for VW"
	^ [:dbf :val | ByteArray withAll: (dbf formatStringFieldLength: len value: val)]
]
