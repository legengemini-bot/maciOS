//
//  OpenCL_Metal.h
//  OpenCL to Metal Bridge Implementation
//

#ifndef OpenCL_Metal_h
#define OpenCL_Metal_h

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>

// OpenCL compatibility types and constants
typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef size_t cl_size_t;
typedef void* cl_platform_id;
typedef void* cl_device_id;
typedef void* cl_context;
typedef void* cl_command_queue;
typedef void* cl_mem;
typedef void* cl_program;
typedef void* cl_kernel;
typedef void* cl_event;

// OpenCL constants
#define CL_SUCCESS 0
#define CL_DEVICE_NOT_FOUND -1
#define CL_DEVICE_NOT_AVAILABLE -2
#define CL_COMPILER_NOT_AVAILABLE -3
#define CL_MEM_OBJECT_ALLOCATION_FAILURE -4
#define CL_OUT_OF_RESOURCES -5
#define CL_OUT_OF_HOST_MEMORY -6
#define CL_PROFILING_INFO_NOT_AVAILABLE -7
#define CL_MEM_COPY_OVERLAP -8
#define CL_IMAGE_FORMAT_MISMATCH -9
#define CL_IMAGE_FORMAT_NOT_SUPPORTED -10
#define CL_BUILD_PROGRAM_FAILURE -11
#define CL_MAP_FAILURE -12
#define CL_INVALID_VALUE -30
#define CL_INVALID_DEVICE_TYPE -31
#define CL_INVALID_PLATFORM -32
#define CL_INVALID_DEVICE -33
#define CL_INVALID_CONTEXT -34
#define CL_INVALID_QUEUE_PROPERTIES -35
#define CL_INVALID_COMMAND_QUEUE -36
#define CL_INVALID_HOST_PTR -37
#define CL_INVALID_MEM_OBJECT -38
#define CL_INVALID_IMAGE_FORMAT_DESCRIPTOR -39
#define CL_INVALID_IMAGE_SIZE -40
#define CL_INVALID_SAMPLER -41
#define CL_INVALID_BINARY -42
#define CL_INVALID_BUILD_OPTIONS -43
#define CL_INVALID_PROGRAM -44
#define CL_INVALID_PROGRAM_EXECUTABLE -45
#define CL_INVALID_KERNEL_NAME -46
#define CL_INVALID_KERNEL_DEFINITION -47
#define CL_INVALID_KERNEL -48
#define CL_INVALID_ARG_INDEX -49
#define CL_INVALID_ARG_VALUE -50
#define CL_INVALID_ARG_SIZE -51
#define CL_INVALID_KERNEL_ARGS -52
#define CL_INVALID_WORK_DIMENSION -53
#define CL_INVALID_WORK_GROUP_SIZE -54
#define CL_INVALID_WORK_ITEM_SIZE -55
#define CL_INVALID_GLOBAL_OFFSET -56
#define CL_INVALID_EVENT_WAIT_LIST -57
#define CL_INVALID_EVENT -58
#define CL_INVALID_OPERATION -59
#define CL_INVALID_GL_OBJECT -60
#define CL_INVALID_BUFFER_SIZE -61
#define CL_INVALID_MIP_LEVEL -62
#define CL_INVALID_GLOBAL_WORK_SIZE -63


// Error codes
#define CL_SUCCESS                     0
#define CL_DEVICE_NOT_FOUND            -1

// cl_device_info enums (minimal set)
typedef enum : cl_uint {
    CL_DEVICE_NAME = 0x102B,
    CL_DEVICE_TYPE = 0x1000,
    CL_DEVICE_MAX_COMPUTE_UNITS = 0x1002,
    CL_DEVICE_GLOBAL_MEM_SIZE = 0x101F,
    CL_DEVICE_LOCAL_MEM_SIZE = 0x1023,
    CL_DEVICE_MAX_WORK_GROUP_SIZE = 0x1004,
} cl_device_info;

typedef cl_uint cl_platform_info;

#define CL_PLATFORM_PROFILE    0x0900
#define CL_PLATFORM_VERSION    0x0901
#define CL_PLATFORM_NAME       0x0902
#define CL_PLATFORM_VENDOR     0x0903
#define CL_PLATFORM_EXTENSIONS 0x0904


// Memory flags
#define CL_MEM_READ_WRITE (1 << 0)
#define CL_MEM_WRITE_ONLY (1 << 1)
#define CL_MEM_READ_ONLY (1 << 2)
#define CL_MEM_USE_HOST_PTR (1 << 3)
#define CL_MEM_ALLOC_HOST_PTR (1 << 4)
#define CL_MEM_COPY_HOST_PTR (1 << 5)

// Device types
#define CL_DEVICE_TYPE_DEFAULT (1 << 0)
#define CL_DEVICE_TYPE_CPU (1 << 1)
#define CL_DEVICE_TYPE_GPU (1 << 2)
#define CL_DEVICE_TYPE_ACCELERATOR (1 << 3)
#define CL_DEVICE_TYPE_ALL 0xFFFFFFFF

typedef cl_uint cl_mem_flags;
typedef cl_uint cl_device_type;

// Internal structures
@interface CLMetalPlatform : NSObject
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray<id<MTLDevice>> *devices;
@end

@interface CLMetalDevice : NSObject
@property (strong, nonatomic) id<MTLDevice> metalDevice;
@property (strong, nonatomic) NSString *name;
@property (nonatomic) cl_device_type type;
@end

@interface CLMetalContext : NSObject
@property (strong, nonatomic) id<MTLDevice> device;
@property (strong, nonatomic) NSMutableArray<CLMetalDevice*> *devices;
@end

@interface CLMetalCommandQueue : NSObject
@property (strong, nonatomic) id<MTLCommandQueue> commandQueue;
@property (strong, nonatomic) CLMetalContext *context;
@end

@interface CLMetalProgram : NSObject
@property (strong, nonatomic) id<MTLLibrary> library;
@property (strong, nonatomic) CLMetalContext *context;
@property (strong, nonatomic) NSString *sourceCode;
@property (strong, nonatomic) NSError *buildError;
@end

@interface CLMetalKernel : NSObject
@property (strong, nonatomic) id<MTLComputePipelineState> pipelineState;
@property (strong, nonatomic) CLMetalProgram *program;
@property (strong, nonatomic) NSString *kernelName;
@property (strong, nonatomic) NSMutableArray *arguments;
@end

@interface CLMetalBuffer : NSObject
@property (strong, nonatomic) id<MTLBuffer> buffer;
@property (nonatomic) cl_mem_flags flags;
@property (nonatomic) size_t size;
@property (strong, nonatomic) CLMetalContext *context;
@end

// Global state management
@interface CLMetalManager : NSObject
+ (instancetype)sharedManager;
@property (strong, nonatomic) NSMutableArray<CLMetalPlatform*> *platforms;
@property (strong, nonatomic) NSMutableDictionary *contexts;
@property (strong, nonatomic) NSMutableDictionary *commandQueues;
@property (strong, nonatomic) NSMutableDictionary *programs;
@property (strong, nonatomic) NSMutableDictionary *kernels;
@property (strong, nonatomic) NSMutableDictionary *buffers;
@end

// OpenCL API Implementation

// Platform API
cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms);

// Device API
cl_int clGetDeviceIDs(cl_platform_id platform, cl_device_type device_type,
                      cl_uint num_entries, cl_device_id *devices, cl_uint *num_devices);

// Context API
cl_context clCreateContext(const void *properties, cl_uint num_devices,
                          const cl_device_id *devices, void *pfn_notify,
                          void *user_data, cl_int *errcode_ret);

cl_int clReleaseContext(cl_context context);

// Command Queue API
cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device,
                                     cl_ulong properties, cl_int *errcode_ret);

cl_int clReleaseCommandQueue(cl_command_queue command_queue);

// Memory Object API
cl_mem clCreateBuffer(cl_context context, cl_mem_flags flags, size_t size,
                      void *host_ptr, cl_int *errcode_ret);

cl_int clReleaseMemObject(cl_mem memobj);

cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer,
                          cl_uint blocking_read, size_t offset, size_t size,
                          void *ptr, cl_uint num_events_in_wait_list,
                          const cl_event *event_wait_list, cl_event *event);

cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer,
                           cl_uint blocking_write, size_t offset, size_t size,
                           const void *ptr, cl_uint num_events_in_wait_list,
                           const cl_event *event_wait_list, cl_event *event);

// Program Object API
cl_program clCreateProgramWithSource(cl_context context, cl_uint count,
                                    const char **strings, const size_t *lengths,
                                    cl_int *errcode_ret);

cl_int clBuildProgram(cl_program program, cl_uint num_devices,
                     const cl_device_id *device_list, const char *options,
                     void *pfn_notify, void *user_data);

cl_int clReleaseProgram(cl_program program);

// Kernel Object API
cl_kernel clCreateKernel(cl_program program, const char *kernel_name,
                        cl_int *errcode_ret);

cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size,
                     const void *arg_value);

cl_int clReleaseKernel(cl_kernel kernel);

// Executing Kernels
cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel,
                             cl_uint work_dim, const size_t *global_work_offset,
                             const size_t *global_work_size, const size_t *local_work_size,
                             cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                             cl_event *event);

// Event API
cl_int clWaitForEvents(cl_uint num_events, const cl_event *event_list);
cl_int clFinish(cl_command_queue command_queue);

#endif /* OpenCL_Metal_h */
//
//  OpenCL_Metal.h
//  OpenCL to Metal Bridge Implementation
//

#ifndef OpenCL_Metal_h
#define OpenCL_Metal_h

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>

// OpenCL compatibility types and constants
typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef size_t cl_size_t;
typedef void* cl_platform_id;
typedef void* cl_device_id;
typedef void* cl_context;
typedef void* cl_command_queue;
typedef void* cl_program;
typedef void* cl_kernel;
typedef void* cl_mem;
typedef void* cl_event;

// OpenCL constants
#define CL_SUCCESS 0
#define CL_DEVICE_NOT_FOUND -1
#define CL_DEVICE_NOT_AVAILABLE -2
#define CL_COMPILER_NOT_AVAILABLE -3
#define CL_MEM_OBJECT_ALLOCATION_FAILURE -4
#define CL_OUT_OF_RESOURCES -5
#define CL_OUT_OF_HOST_MEMORY -6
#define CL_PROFILING_INFO_NOT_AVAILABLE -7
#define CL_MEM_COPY_OVERLAP -8
#define CL_IMAGE_FORMAT_MISMATCH -9
#define CL_IMAGE_FORMAT_NOT_SUPPORTED -10
#define CL_BUILD_PROGRAM_FAILURE -11
#define CL_MAP_FAILURE -12
#define CL_INVALID_VALUE -30
#define CL_INVALID_DEVICE_TYPE -31
#define CL_INVALID_PLATFORM -32
#define CL_INVALID_DEVICE -33
#define CL_INVALID_CONTEXT -34
#define CL_INVALID_QUEUE_PROPERTIES -35
#define CL_INVALID_COMMAND_QUEUE -36
#define CL_INVALID_HOST_PTR -37
#define CL_INVALID_MEM_OBJECT -38
#define CL_INVALID_IMAGE_FORMAT_DESCRIPTOR -39
#define CL_INVALID_IMAGE_SIZE -40
#define CL_INVALID_SAMPLER -41
#define CL_INVALID_BINARY -42
#define CL_INVALID_BUILD_OPTIONS -43
#define CL_INVALID_PROGRAM -44
#define CL_INVALID_PROGRAM_EXECUTABLE -45
#define CL_INVALID_KERNEL_NAME -46
#define CL_INVALID_KERNEL_DEFINITION -47
#define CL_INVALID_KERNEL -48
#define CL_INVALID_ARG_INDEX -49
#define CL_INVALID_ARG_VALUE -50
#define CL_INVALID_ARG_SIZE -51
#define CL_INVALID_KERNEL_ARGS -52
#define CL_INVALID_WORK_DIMENSION -53
#define CL_INVALID_WORK_GROUP_SIZE -54
#define CL_INVALID_WORK_ITEM_SIZE -55
#define CL_INVALID_GLOBAL_OFFSET -56
#define CL_INVALID_EVENT_WAIT_LIST -57
#define CL_INVALID_EVENT -58
#define CL_INVALID_OPERATION -59
#define CL_INVALID_GL_OBJECT -60
#define CL_INVALID_BUFFER_SIZE -61
#define CL_INVALID_MIP_LEVEL -62
#define CL_INVALID_GLOBAL_WORK_SIZE -63

// Memory flags
#define CL_MEM_READ_WRITE (1 << 0)
#define CL_MEM_WRITE_ONLY (1 << 1)
#define CL_MEM_READ_ONLY (1 << 2)
#define CL_MEM_USE_HOST_PTR (1 << 3)
#define CL_MEM_ALLOC_HOST_PTR (1 << 4)
#define CL_MEM_COPY_HOST_PTR (1 << 5)

// Device types
#define CL_DEVICE_TYPE_DEFAULT (1 << 0)
#define CL_DEVICE_TYPE_CPU (1 << 1)
#define CL_DEVICE_TYPE_GPU (1 << 2)
#define CL_DEVICE_TYPE_ACCELERATOR (1 << 3)
#define CL_DEVICE_TYPE_ALL 0xFFFFFFFF

typedef cl_uint cl_mem_flags;
typedef cl_uint cl_device_type;

// Internal structures
@interface CLMetalPlatform : NSObject
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray<id<MTLDevice>> *devices;
@end

@interface CLMetalDevice : NSObject
@property (strong, nonatomic) id<MTLDevice> metalDevice;
@property (strong, nonatomic) NSString *name;
@property (nonatomic) cl_device_type type;
@end

@interface CLMetalContext : NSObject
@property (strong, nonatomic) id<MTLDevice> device;
@property (strong, nonatomic) NSMutableArray<CLMetalDevice*> *devices;
@end

@interface CLMetalCommandQueue : NSObject
@property (strong, nonatomic) id<MTLCommandQueue> commandQueue;
@property (strong, nonatomic) CLMetalContext *context;
@end

@interface CLMetalProgram : NSObject
@property (strong, nonatomic) id<MTLLibrary> library;
@property (strong, nonatomic) CLMetalContext *context;
@property (strong, nonatomic) NSString *sourceCode;
@property (strong, nonatomic) NSError *buildError;
@end

@interface CLMetalKernel : NSObject
@property (strong, nonatomic) id<MTLComputePipelineState> pipelineState;
@property (strong, nonatomic) CLMetalProgram *program;
@property (strong, nonatomic) NSString *kernelName;
@property (strong, nonatomic) NSMutableArray *arguments;
@end

@interface CLMetalBuffer : NSObject
@property (strong, nonatomic) id<MTLBuffer> buffer;
@property (nonatomic) cl_mem_flags flags;
@property (nonatomic) size_t size;
@property (strong, nonatomic) CLMetalContext *context;
@end

// Global state management
@interface CLMetalManager : NSObject
+ (instancetype)sharedManager;
@property (strong, nonatomic) NSMutableArray<CLMetalPlatform*> *platforms;
@property (strong, nonatomic) NSMutableDictionary *contexts;
@property (strong, nonatomic) NSMutableDictionary *commandQueues;
@property (strong, nonatomic) NSMutableDictionary *programs;
@property (strong, nonatomic) NSMutableDictionary *kernels;
@property (strong, nonatomic) NSMutableDictionary *buffers;
@end

// OpenCL API Implementation

// Platform API
cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms);

// Device API
cl_int clGetDeviceIDs(cl_platform_id platform, cl_device_type device_type,
                      cl_uint num_entries, cl_device_id *devices, cl_uint *num_devices);

// Context API
cl_context clCreateContext(const void *properties, cl_uint num_devices,
                          const cl_device_id *devices, void *pfn_notify,
                          void *user_data, cl_int *errcode_ret);

cl_int clReleaseContext(cl_context context);

// Command Queue API
cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device,
                                     cl_ulong properties, cl_int *errcode_ret);

cl_int clReleaseCommandQueue(cl_command_queue command_queue);

// Memory Object API
cl_mem clCreateBuffer(cl_context context, cl_mem_flags flags, size_t size,
                      void *host_ptr, cl_int *errcode_ret);

cl_int clReleaseMemObject(cl_mem memobj);

cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer,
                          cl_uint blocking_read, size_t offset, size_t size,
                          void *ptr, cl_uint num_events_in_wait_list,
                          const cl_event *event_wait_list, cl_event *event);

cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer,
                           cl_uint blocking_write, size_t offset, size_t size,
                           const void *ptr, cl_uint num_events_in_wait_list,
                           const cl_event *event_wait_list, cl_event *event);

// Program Object API
cl_program clCreateProgramWithSource(cl_context context, cl_uint count,
                                    const char **strings, const size_t *lengths,
                                    cl_int *errcode_ret);

cl_int clBuildProgram(cl_program program, cl_uint num_devices,
                     const cl_device_id *device_list, const char *options,
                     void *pfn_notify, void *user_data);

cl_int clReleaseProgram(cl_program program);

// Kernel Object API
cl_kernel clCreateKernel(cl_program program, const char *kernel_name,
                        cl_int *errcode_ret);

cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size,
                     const void *arg_value);

cl_int clReleaseKernel(cl_kernel kernel);

// Executing Kernels
cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel,
                             cl_uint work_dim, const size_t *global_work_offset,
                             const size_t *global_work_size, const size_t *local_work_size,
                             cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                             cl_event *event);

// Event API
cl_int clWaitForEvents(cl_uint num_events, const cl_event *event_list);
cl_int clFinish(cl_command_queue command_queue);

#endif /* OpenCL_Metal_h */
