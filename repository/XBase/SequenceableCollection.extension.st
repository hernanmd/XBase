Extension { #name : #SequenceableCollection }

{ #category : #'*XBase-CSV' }
SequenceableCollection >> asCSVLine [
	"Convert to a string with commas between items. Double-Quote all Strings.
	 Useful for labels for PopUpMenus."
	| stream |
	stream := WriteStream on: (String new: 200).
	self do: [:each |
		| item |
		item := (each isKindOf: String) 
			ifTrue: [ each ] 
			ifFalse: [ (each respondsTo: #printCSVString) 
				ifTrue: [ each printCSVString ] 
				ifFalse: [ each printString ] ].
		(item includesAnyOf: (Array with: $, with: Character cr with: Character lf))
			ifTrue: [
				stream 
					nextPut: $"; 
					nextPutAll: (item escapeAll: '"' with: $"); 
					nextPutAll: '",' ]
			ifFalse: [	
				stream 
					nextPutAll: item; 
					nextPut: $, ] ].
	self size > 0 ifTrue: [stream skip: -1].
	^ stream contents
]
