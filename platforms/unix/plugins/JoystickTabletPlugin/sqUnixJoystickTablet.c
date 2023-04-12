/* sqUnixJoystickTablet.c -- support for joysticks and graphics tablets
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *
 *   This file is part of Unix Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * Author: davidf@afeka.ac.il
 * Author: Tobias Pape
 */

#include "sq.h"

#include <assert.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <poll.h>
#if defined(HAVE_LINUX_INPUT_H)
#include <linux/input.h>
#else
#error Not currently supported
#endif

#include "JoystickTabletPlugin.h"

#define DEVICE_DIR      "/dev/input/by-id/"
#define JOYSTICK_TOKEN          "-event-joystick"
#define MAX_JOYSTICK    2
#define BITS_IN_WORD    32

#define EVENT_BUF_SIZE  10

/*
 * For compatibility with olden linuxen <=3.10*
 */
#if !defined(BTN_NORTH) && defined(BTN_X)
#define BTN_NORTH BTN_X
#endif
#if !defined(BTN_EAST) && defined(BTN_B)
#define BTN_EAST BTN_B
#endif
#if !defined(BTN_SOUTH) && defined(BTN_A)
#define BTN_SOUTH BTN_A
#endif
#if !defined(BTN_WEST) && defined(BTN_Y)
#define BTN_WEST BTN_Y
#endif


typedef struct _input_event {
    struct timeval time;
    unsigned short type;
    unsigned short code;
    unsigned int value;
} input_event;

typedef struct {
    int fd;
    int button_index[4]; // key code for each button
    int button_state[4];
    struct input_absinfo abs_x;
    struct input_absinfo abs_y;
} joystick_state_t ;

joystick_state_t joystick_state[MAX_JOYSTICK];
int joystick_count;

int
testBit(int i, uint32_t* x) {
    return x[i / BITS_IN_WORD] & (1 << (i % BITS_IN_WORD));
}

int
enumerateJoysticks()
{
    char dev_path[PATH_MAX];
    struct dirent* current_entry;
    DIR* device_dir;
    int result;

    result = 1;
    errno = 0;
    device_dir = opendir(DEVICE_DIR);

    if (device_dir == NULL) {
        perror("opendir");
        return 0;
    }

    current_entry = readdir(device_dir);

    if (current_entry == NULL) {
        perror("readdir");
        result = 0;
    }

    while (current_entry != NULL) {

        if (current_entry->d_type == DT_LNK &&
            strstr(current_entry->d_name, JOYSTICK_TOKEN) != NULL &&
            strlen(current_entry->d_name) + strlen(DEVICE_DIR) < PATH_MAX + 1 &&
            joystick_count < MAX_JOYSTICK) {

            dev_path[0] = '\0';
            strcat(dev_path, DEVICE_DIR);
            strcat(dev_path, current_entry->d_name);

            joystick_state[joystick_count].fd = open(dev_path, O_RDONLY);

            if (joystick_state[joystick_count].fd != -1) {
                ++joystick_count;
            }

        }
        current_entry = readdir(device_dir);
    }

    closedir(device_dir);

    return result;
}

int
detectButtons(joystick_state_t* pj)
{
        int fd;
        uint32_t supported_keys[KEY_CNT / BITS_IN_WORD + 1] = { 0 };

        fd = pj->fd;

        if (ioctl(fd, EVIOCGBIT(EV_KEY, KEY_MAX), &supported_keys) == -1) {
                perror("ioctl");
                return -1;
        }

        if (testBit(BTN_JOYSTICK, supported_keys) == 0 && testBit(BTN_GAMEPAD, supported_keys) == 0) {
                // we did not find any buttons, something is wrong with this device.
                return -1;
        }

        if (testBit(BTN_JOYSTICK, supported_keys) == 1) {
                // it's an old style joystick device
                pj->button_index[0] = BTN_JOYSTICK;
                pj->button_index[1] = BTN_THUMB;
                pj->button_index[2] = BTN_THUMB2;
                pj->button_index[3] = BTN_TOP;
        } else {
                // it's a modern gamepad device
                pj->button_index[0] = BTN_NORTH;
                pj->button_index[1] = BTN_EAST;
                pj->button_index[2] = BTN_SOUTH;
                pj->button_index[3] = BTN_WEST;
        }

        return 1;
}

int
detectAxes(joystick_state_t* pj)
{
        int fd;
        uint32_t supported_axes[ABS_CNT / BITS_IN_WORD + 1] = { 0 };

        fd = pj->fd;

        if (ioctl(fd, EVIOCGBIT(EV_ABS, ABS_MAX), &supported_axes) == -1) {
                perror("ioctl");
            return -1;
        }

        if (testBit(ABS_X, supported_axes) == 0 || testBit(ABS_Y, supported_axes) == 0) {
                // something is wrong, we could not find both required axes
                return -1;
        }

        return 1;
}

int
readJoystickState(joystick_state_t* pj)
{
        if (ioctl(pj->fd, EVIOCGABS(ABS_X), &pj->abs_x) == -1)
                return -1;

        if (ioctl(pj->fd, EVIOCGABS(ABS_Y), &pj->abs_y) == -1)
                return -1;

        return 1;
}

int
initializeJoystickState(joystick_state_t* pj)
{
        if (detectButtons(pj) == -1) {
                return 0;
        }

        if (detectAxes(pj) == -1) {
                return 0;
        }

        if (readJoystickState(pj) == -1) {
                return 0;
        }

        return 1;
}

int
joystickInit(void)
{
        if (enumerateJoysticks() == 0) {
                return 0;
        }

        for (int i = 0; i < joystick_count; ++i) {
                if (initializeJoystickState(&joystick_state[i]) == 0)
                        return 0;
        }

        return 1;
}

double
map(double x, double from_begin,double from_end, double to_begin, double to_end)
{
        return to_begin + (to_end-to_begin)*(x-from_begin)/(from_end-from_begin);
}

int
readNewEvents(joystick_state_t* pj)
{
        input_event event[EVENT_BUF_SIZE];
        int count;

        count = read(pj->fd, &event, sizeof(input_event)*EVENT_BUF_SIZE);

        for (int i = 0 ; i < count / sizeof(input_event) ; ++i) {

                if (event[i].type == EV_KEY) {
                        for (int j = 0 ; j < 4 ; ++j) {
                                if (pj->button_index[j] == event[i].code) {
                                        pj->button_state[j] = event[i].value;
                                }
                        }
                }

                if (event[i].type == EV_ABS) {
                        if (event[i].code == ABS_X) {
                                pj->abs_x.value = event[i].value;
                        }

                        if (event[i].code == ABS_Y) {
                                pj->abs_y.value = event[i].value;
                        }
                }
        }
        return 1;
}

int
joystickRead(int index)
{
        uint32_t result;
        joystick_state_t* pj;
        struct pollfd poll_fds;
        int ret;
        int x, y;

        result = 0;
        --index;

        if (index < 0 || index >= joystick_count)
                return 0;

        pj = &joystick_state[index];

        poll_fds.fd = pj->fd;
        poll_fds.events = POLLIN;

        ret = poll(&poll_fds, 1, 0);

        if (ret == -1)
                return 0;

        if (ret > 0) {
                ret = readNewEvents(pj);

                if (ret == -1)
                        return 0;
        }

        x = (int)map(pj->abs_x.value, pj->abs_x.minimum, pj->abs_x.maximum, 0, 0x7FF);
        y = (int)map(pj->abs_y.value, pj->abs_y.minimum, pj->abs_y.maximum, 0, 0x7FF);

        return (1 << 27) | (pj->button_state[0] << 22) | (pj->button_state[1] << 23) | (pj->button_state[2] << 24) | (pj->button_state[3] << 25) | (y << 11) | x;

}

int
joystickShutdown(void)
{
        for (int i = 0; i < joystick_count; ++i) {
                close(joystick_state[i].fd);
        }

        joystick_count = 0;
}


/* we don't have any tablets */
int tabletInit(void)
{
  return 0;
}

int tabletGetParameters(int cursorIndex, int result[])
{
  return 0;
}

int tabletRead(int cursorIndex, int result[])
{
  return 0;
}

int tabletResultSize(void)
{
  return 0;
}
