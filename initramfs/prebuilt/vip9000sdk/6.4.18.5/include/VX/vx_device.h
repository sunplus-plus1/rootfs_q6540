/****************************************************************************
*
*    Copyright 2017 - 2024 Vivante Corporation, Santa Clara, California.
*    All Rights Reserved.
*
*    Permission is hereby granted, free of charge, to any person obtaining
*    a copy of this software and associated documentation files (the
*    'Software'), to deal in the Software without restriction, including
*    without limitation the rights to use, copy, modify, merge, publish,
*    distribute, sub license, and/or sell copies of the Software, and to
*    permit persons to whom the Software is furnished to do so, subject
*    to the following conditions:
*
*    The above copyright notice and this permission notice (including the
*    next paragraph) shall be included in all copies or substantial
*    portions of the Software.
*
*    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
*    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
*    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
*    IN NO EVENT SHALL VIVANTE AND/OR ITS SUPPLIERS BE LIABLE FOR ANY
*    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
*    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
*    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
*****************************************************************************/

#ifndef __VX_DEVICE_H__
#define __VX_DEVICE_H__

#ifdef  __cplusplus
extern "C" {
#endif

typedef struct _vx_device_s *vx_device;

typedef struct _vx_device_info_s
{
    vx_uint32  compute_core_count;
}
vx_device_info_s;

typedef struct _vx_device_info_s *vx_device_info;

/* Query devices from system */
VX_API_ENTRY vx_status VX_API_CALL vxGetDevices(
    vx_context   context,
    vx_device*   devices,
    vx_uint32*   num_devices);

/* Query device information */
VX_API_ENTRY vx_status VX_API_CALL vxGetDeviceInfo(
    vx_device           device,
    vx_device_info      device_info);

/* Create sub device by specify range of compute cores */
VX_API_ENTRY vx_status VX_API_CALL vxCreateSubDevice(
    vx_device    device,
    vx_uint32    start,
    vx_uint32    count,
    vx_device*   sub_device);

/* Bind the devices to a graph */
VX_API_ENTRY vx_status VX_API_CALL vxBindDevices(
    vx_graph     graph,
    vx_uint32    num_devices,
    vx_device*   devices);

/* Release a reference to a device */
VX_API_ENTRY vx_status VX_API_CALL vxReleaseDevice(
    vx_device*   device);

#ifdef  __cplusplus
}
#endif

#endif
