"
A StackInterpreterSimulatorImageMorph is an ImageMorph The StackInterpreterSimulator paints its world on me.

If tty can get event forwarding working along the HandMorph->StackInterpreterSimulatorMorphicModel->StackInterpreterSimulator path, then then I don't need to exist.

If event forwarding attempt above fails, then I may need to handle it.


Instance Variables


"
Class {
	#name : #StackInterpreterSimulatorImageMorph,
	#superclass : #ImageMorph,
	#instVars : [
		'eventForwarder'
	],
	#category : #'VMMaker-InterpreterSimulation-Morphic'
}
