//
//  detector.h
//  yolo-ios
//
//  Created by William Söder on 2021-04-07.
//

#ifndef detector_h
#define detector_h

#include <stdio.h>

void train_detector(char *datacfg, char *cfgfile, char *weightfile, int *gpus, int ngpus, int clear);

#endif /* detector_h */
