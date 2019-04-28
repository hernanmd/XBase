Class {
	#name : #BaselineOfXBase,
	#superclass : #BaselineOf,
	#category : #BaselineOfXBase
}

{ #category : #baselines }
BaselineOfXBase >> baseline: spec [
	<baseline>

	spec for: #'common' do: [
		spec package: #XBase. 
		
		spec 
			group: 'Core' with: #(#'XBase') ].

]
