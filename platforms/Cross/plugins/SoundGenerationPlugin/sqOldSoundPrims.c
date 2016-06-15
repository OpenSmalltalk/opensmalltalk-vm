/* Automatically generated from Squeak on (4 January 1998 3:05:25 am ) */

#include "sq.h"

#if OLD_SOUND_PRIMS

/*** Imported Functions/Variables ***/
extern sqInt stackValue(sqInt);
extern sqInt successFlag;

/*** Variables ***/

/*** Function Prototypes ***/
int primFMSoundmixSampleCountintostartingAtpan(void);
int primPluckedSoundmixSampleCountintostartingAtpan(void);
int primSampledSoundmixSampleCountintostartingAtpan(void);
int primWaveTableSoundmixSampleCountintostartingAtpan(void);
int oldprimSampledSoundmixSampleCountintostartingAtleftVolrightVol(void);

int primFMSoundmixSampleCountintostartingAtpan(void) {
    int rcvr;
    int n;
    short int *aSoundBuffer;
    int startIndex;
    int pan;
    int mySample;
    int sample;
    int lastIndex;
    int channelIndex;
    int i;
    short int *waveTable;
    int waveTableSize;
    int count;
    int amplitude;
    int increment;
    int index;
    int modulation;
    int offsetIncrement;
    int offsetIndex;

	rcvr = stackValue(4);
	n = checkedIntegerValueOf(stackValue(3));
	aSoundBuffer = arrayValueOf(stackValue(2));
	startIndex = checkedIntegerValueOf(stackValue(1));
	pan = checkedIntegerValueOf(stackValue(0));
	waveTable = fetchArrayofObject(1, rcvr);
	waveTableSize = fetchIntegerofObject(2, rcvr);
	count = fetchIntegerofObject(4, rcvr);
	amplitude = fetchIntegerofObject(6, rcvr);
	increment = fetchIntegerofObject(8, rcvr);
	index = fetchIntegerofObject(9, rcvr);
	modulation = fetchIntegerofObject(11, rcvr);
	offsetIncrement = fetchIntegerofObject(14, rcvr);
	offsetIndex = fetchIntegerofObject(15, rcvr);
	if (!(successFlag)) {
		return null;
	}
	lastIndex = (startIndex + n) - 1;
	for (i = startIndex; i <= lastIndex; i += 1) {
		mySample = (amplitude * (waveTable[index - 1])) / 1000;
		if (pan > 0) {
			channelIndex = 2 * i;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * pan) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		if (pan < 1000) {
			channelIndex = (2 * i) - 1;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * (1000 - pan)) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		index = (index + increment) + ((modulation * (waveTable[offsetIndex - 1])) / 1000000);
		if (index > waveTableSize) {
			index -= waveTableSize;
		}
		if (index < 1) {
			index += waveTableSize;
		}
		offsetIndex += offsetIncrement;
		if (offsetIndex > waveTableSize) {
			offsetIndex -= waveTableSize;
		}
	}
	count -= n;
	storeIntegerofObjectwithValue(4, rcvr, count);
	storeIntegerofObjectwithValue(9, rcvr, index);
	storeIntegerofObjectwithValue(15, rcvr, offsetIndex);
	pop(4);
}

int primPluckedSoundmixSampleCountintostartingAtpan(void) {
    int rcvr;
    int n;
    short int *aSoundBuffer;
    int startIndex;
    int pan;
    int lastIndex;
    int channelIndex;
    int i;
    int sample;
    int mySample;
    int thisIndex;
    int nextIndex;
    int count;
    short int *ring;
    int ringSize;
    int ringIndx;

	rcvr = stackValue(4);
	n = checkedIntegerValueOf(stackValue(3));
	aSoundBuffer = arrayValueOf(stackValue(2));
	startIndex = checkedIntegerValueOf(stackValue(1));
	pan = checkedIntegerValueOf(stackValue(0));
	count = fetchIntegerofObject(2, rcvr);
	ring = fetchArrayofObject(4, rcvr);
	ringSize = fetchIntegerofObject(5, rcvr);
	ringIndx = fetchIntegerofObject(6, rcvr);
	if (!(successFlag)) {
		return null;
	}
	lastIndex = (startIndex + n) - 1;
	thisIndex = ringIndx;
	for (i = startIndex; i <= lastIndex; i += 1) {
		nextIndex = (thisIndex % ringSize) + 1;
		mySample = ((ring[thisIndex - 1]) + (ring[nextIndex - 1])) / 2;
		ring[thisIndex - 1] = mySample;
		thisIndex = nextIndex;
		if (pan > 0) {
			channelIndex = 2 * i;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * pan) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		if (pan < 1000) {
			channelIndex = (2 * i) - 1;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * (1000 - pan)) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
	}
	ringIndx = nextIndex;
	count -= n;
	storeIntegerofObjectwithValue(2, rcvr, count);
	storeIntegerofObjectwithValue(6, rcvr, ringIndx);
	pop(4);
}

int primSampledSoundmixSampleCountintostartingAtpan(void) {
    int rcvr;
    int n;
    short int *aSoundBuffer;
    int startIndex;
    int pan;
    int lastIndex;
    int i;
    int channelIndex;
    int sample;
    int sampleIndex;
    int thisSample;
    short int *samples;
    int samplesSize;
    int incrementTimes1000;
    int count;
    int indexTimes1000;

	rcvr = stackValue(4);
	n = checkedIntegerValueOf(stackValue(3));
	aSoundBuffer = arrayValueOf(stackValue(2));
	startIndex = checkedIntegerValueOf(stackValue(1));
	pan = checkedIntegerValueOf(stackValue(0));
	samples = fetchArrayofObject(1, rcvr);
	samplesSize = fetchIntegerofObject(2, rcvr);
	incrementTimes1000 = fetchIntegerofObject(3, rcvr);
	count = fetchIntegerofObject(5, rcvr);
	indexTimes1000 = fetchIntegerofObject(6, rcvr);
	if (!(successFlag)) {
		return null;
	}
	lastIndex = (startIndex + n) - 1;
	i = startIndex;
	sampleIndex = indexTimes1000 / 1000;
	while ((sampleIndex <= samplesSize) && (i <= lastIndex)) {
		thisSample = samples[sampleIndex - 1];
		if (pan > 0) {
			channelIndex = 2 * i;
			sample = (aSoundBuffer[channelIndex - 1]) + ((thisSample * pan) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		if (pan < 1000) {
			channelIndex = (2 * i) - 1;
			sample = (aSoundBuffer[channelIndex - 1]) + ((thisSample * (1000 - pan)) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		indexTimes1000 += incrementTimes1000;
		sampleIndex = indexTimes1000 / 1000;
		i += 1;
	}
	count -= n;
	storeIntegerofObjectwithValue(5, rcvr, count);
	storeIntegerofObjectwithValue(6, rcvr, indexTimes1000);
	pop(4);
}

int primWaveTableSoundmixSampleCountintostartingAtpan(void) {
    int rcvr;
    int n;
    short int *aSoundBuffer;
    int startIndex;
    int pan;
    int lastIndex;
    int channelIndex;
    int i;
    int mySample;
    int sample;
    short int *waveTable;
    int waveTableSize;
    int count;
    int amplitude;
    int increment;
    int index;

	rcvr = stackValue(4);
	n = checkedIntegerValueOf(stackValue(3));
	aSoundBuffer = arrayValueOf(stackValue(2));
	startIndex = checkedIntegerValueOf(stackValue(1));
	pan = checkedIntegerValueOf(stackValue(0));
	waveTable = fetchArrayofObject(1, rcvr);
	waveTableSize = fetchIntegerofObject(2, rcvr);
	count = fetchIntegerofObject(4, rcvr);
	amplitude = fetchIntegerofObject(6, rcvr);
	increment = fetchIntegerofObject(8, rcvr);
	index = fetchIntegerofObject(9, rcvr);
	if (!(successFlag)) {
		return null;
	}
	lastIndex = (startIndex + n) - 1;
	for (i = startIndex; i <= lastIndex; i += 1) {
		mySample = (amplitude * (waveTable[index - 1])) / 1000;
		if (pan > 0) {
			channelIndex = 2 * i;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * pan) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		if (pan < 1000) {
			channelIndex = (2 * i) - 1;
			sample = (aSoundBuffer[channelIndex - 1]) + ((mySample * (1000 - pan)) / 1000);
			if (sample > 32767) {
				sample = 32767;
			}
			if (sample < -32767) {
				sample = -32767;
			}
			aSoundBuffer[channelIndex - 1] = sample;
		}
		index += increment;
		if (index > waveTableSize) {
			index -= waveTableSize;
		}
	}
	count -= n;
	storeIntegerofObjectwithValue(4, rcvr, count);
	storeIntegerofObjectwithValue(9, rcvr, index);
	pop(4);
}

int oldprimSampledSoundmixSampleCountintostartingAtleftVolrightVol(void) {
    int rcvr;
    int n;
    short int *aSoundBuffer;
    int startIndex;
    int leftVol;
    int rightVol;
    int sliceIndex;
    int sampleIndex;
    int sample;
    int s;
    int lastIndex;
    int i;
    int scaledVol;
    int scaledVolIncr;
    int scaledVolLimit;
    int count;
    short int *samples;
    int samplesSize;
    int incrementTimes1000;
    int indexTimes1000;

	rcvr = stackValue(5);
	n = checkedIntegerValueOf(stackValue(4));
	aSoundBuffer = arrayValueOf(stackValue(3));
	aSoundBuffer -= 1;
	startIndex = checkedIntegerValueOf(stackValue(2));
	leftVol = checkedIntegerValueOf(stackValue(1));
	rightVol = checkedIntegerValueOf(stackValue(0));
	scaledVol = fetchIntegerofObject(3, rcvr);
	scaledVolIncr = fetchIntegerofObject(4, rcvr);
	scaledVolLimit = fetchIntegerofObject(5, rcvr);
	count = fetchIntegerofObject(7, rcvr);
	samples = fetchArrayofObject(8, rcvr);
	samples -= 1;
	samplesSize = fetchIntegerofObject(10, rcvr);
	incrementTimes1000 = fetchIntegerofObject(11, rcvr);
	indexTimes1000 = fetchIntegerofObject(12, rcvr);
	if (!(successFlag)) {
		return null;
	}
	lastIndex = (startIndex + n) - 1;
	sliceIndex = startIndex;
	sampleIndex = indexTimes1000 / 1000;
	while ((sampleIndex <= samplesSize) && (sliceIndex <= lastIndex)) {
		sample = ((int) ((samples[sampleIndex]) * scaledVol) >> 15);
		if (leftVol > 0) {
			i = (2 * sliceIndex) - 1;
			s = (aSoundBuffer[i]) + (((int) (sample * leftVol) >> 15));
			if (s > 32767) {
				s = 32767;
			}
			if (s < -32767) {
				s = -32767;
			}
			aSoundBuffer[i] = s;
		}
		if (rightVol > 0) {
			i = 2 * sliceIndex;
			s = (aSoundBuffer[i]) + (((int) (sample * rightVol) >> 15));
			if (s > 32767) {
				s = 32767;
			}
			if (s < -32767) {
				s = -32767;
			}
			aSoundBuffer[i] = s;
		}
		if (scaledVolIncr != 0) {
			scaledVol += scaledVolIncr;
			if (((scaledVolIncr > 0) && (scaledVol >= scaledVolLimit)) || ((scaledVolIncr < 0) && (scaledVol <= scaledVolLimit))) {
				scaledVol = scaledVolLimit;
				scaledVolIncr = 0;
			}
		}
		indexTimes1000 += incrementTimes1000;
		sampleIndex = indexTimes1000 / 1000;
		sliceIndex += 1;
	}
	count -= n;
	if (!(successFlag)) {
		return null;
	}
	storeIntegerofObjectwithValue(3, rcvr, scaledVol);
	storeIntegerofObjectwithValue(4, rcvr, scaledVolIncr);
	storeIntegerofObjectwithValue(7, rcvr, count);
	storeIntegerofObjectwithValue(12, rcvr, indexTimes1000);
	pop(5);
}
#endif /* OLD_SOUND_PRIMS */
