Class {
	#name : #XBaseMemoFile,
	#superclass : #Object,
	#instVars : [
		'memoFileName',
		'memoFileStream',
		'blocksize'
	],
	#category : #'XBase-Base'
}

{ #category : #initialization }
XBaseMemoFile class >> openForDbfFilename: dbfFileName [  
	^ self new openForDbfFilename: dbfFileName 
]

{ #category : #'initialize-release' }
XBaseMemoFile >> close [

	memoFileStream ifNotNil: [ memoFileStream close ].
	memoFileStream := nil.
]

{ #category : #initialization }
XBaseMemoFile >> initialize [ 

	super initialize.
	blocksize := 512.
]

{ #category : #initialization }
XBaseMemoFile >> memoAt: blockIndex [
	| memo |

	memoFileStream position: blockIndex * blocksize .
	memo := memoFileStream upTo: (Character value: 16r1a).
	^ memo

]

{ #category : #initialization }
XBaseMemoFile >> openForDbfFilename: dbfFileName [

	memoFileName := dbfFileName , '.DBT'.
	memoFileStream := memoFileName asFileReference.
	memoFileStream 
		ifNil: [ ^ self error: memoFileName, ': memo file cannot be opened read/write' ].
	
	"Don't know any magic number checks, will just have to assume DBT extension is a DBT file"

]
