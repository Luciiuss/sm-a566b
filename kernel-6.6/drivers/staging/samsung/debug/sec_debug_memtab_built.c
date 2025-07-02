// SPDX-License-Identifier: GPL-2.0
/*
 * sec_debug_memtab.c
 *
 * Copyright (c) 2020 Samsung Electronics Co., Ltd
 *              http://www.samsung.com
 *
 *  This program is free software; you can redistribute  it and/or modify it
 *  under  the terms of  the GNU General  Public License as published by the
 *  Free Software Foundation;  either version 2 of the  License, or (at your
 *  option) any later version.
 *
 */

#include <linux/sched.h>
#include <linux/spinlock.h>
#include <linux/rwsem.h>
#include <linux/rtmutex.h>
#include <linux/workqueue.h>
#include <linux/xarray.h>
#include <linux/sched/cputime.h>
#include <linux/device.h>

#include <linux/sec_debug_built.h>

#include "../../../kernel/sched/sched.h"
#include "sec_debug_internal.h"

#define DEFINE_MEMBER_TYPE	SECDBG_DEFINE_MEMBER_TYPE

extern struct secdbg_member_type __start__secdbg_member_table[];
extern struct secdbg_member_type __stop__secdbg_member_table[];

void secdbg_base_built_set_memtab_info(struct sec_debug_memtab *mtab)
{
	mtab->table_start_pa = __pa(__start__secdbg_member_table);
	mtab->table_end_pa = __pa(__stop__secdbg_member_table);
}

DEFINE_MEMBER_TYPE(task_struct_pid, task_struct, pid);
DEFINE_MEMBER_TYPE(task_struct_comm, task_struct, comm);
DEFINE_MEMBER_TYPE(thread_info_flags, thread_info, flags);
DEFINE_MEMBER_TYPE(task_struct_state, task_struct, __state);
DEFINE_MEMBER_TYPE(task_struct_exit_state, task_struct, exit_state);
DEFINE_MEMBER_TYPE(task_struct_stack, task_struct, stack);
DEFINE_MEMBER_TYPE(task_struct_flags, task_struct, flags);
DEFINE_MEMBER_TYPE(task_struct_on_cpu, task_struct, on_cpu);
DEFINE_MEMBER_TYPE(task_struct_on_rq, task_struct, on_rq);
DEFINE_MEMBER_TYPE(task_struct_sched_class, task_struct, sched_class);
DEFINE_MEMBER_TYPE(task_struct_cpu, task_struct, thread_info.cpu);
DEFINE_MEMBER_TYPE(task_struct_ssdbg_wait__type, task_struct, android_oem_data1[0]);
DEFINE_MEMBER_TYPE(task_struct_ssdbg_wait__data, task_struct, android_oem_data1[1]);
#ifdef CONFIG_DEBUG_SPINLOCK
DEFINE_MEMBER_TYPE(raw_spinlock_owner_cpu, raw_spinlock, owner_cpu);
DEFINE_MEMBER_TYPE(raw_spinlock_owner, raw_spinlock, owner);
#endif
DEFINE_MEMBER_TYPE(rw_semaphore_count, rw_semaphore, count);
DEFINE_MEMBER_TYPE(rw_semaphore_owner, rw_semaphore, owner);
#ifdef CONFIG_RT_MUTEXES
DEFINE_MEMBER_TYPE(rt_mutex_owner, rt_mutex_base, owner);
#endif
DEFINE_MEMBER_TYPE(task_struct_normal_prio, task_struct, normal_prio);
DEFINE_MEMBER_TYPE(task_struct_rt_priority, task_struct, rt_priority);
DEFINE_MEMBER_TYPE(task_struct_cpus_ptr, task_struct, cpus_ptr);
DEFINE_MEMBER_TYPE(task_struct_se__vruntime, task_struct, se.vruntime);
DEFINE_MEMBER_TYPE(task_struct_se__avg__load_avg, task_struct, se.avg.load_avg);
DEFINE_MEMBER_TYPE(task_struct_se__avg__util_avg, task_struct, se.avg.util_avg);
DEFINE_MEMBER_TYPE(rq_curr, rq, curr);
#ifdef CONFIG_ARM64_PTR_AUTH
DEFINE_MEMBER_TYPE(task_struct_thread__keys_kernel, task_struct, thread.keys_kernel);
#endif
DEFINE_MEMBER_TYPE(work_struct_data, work_struct, data);
DEFINE_MEMBER_TYPE(work_struct_func, work_struct, func);
DEFINE_MEMBER_TYPE(xarray_xa_head, xarray, xa_head);
DEFINE_MEMBER_TYPE(xa_node_slots, xa_node, slots);
#ifdef CONFIG_STACKPROTECTOR_PER_TASK
DEFINE_MEMBER_TYPE(task_struct_stack_canary, task_struct, stack_canary);
#endif
DEFINE_MEMBER_TYPE(irq_desc_action, irq_desc, action);
DEFINE_MEMBER_TYPE(irq_desc_irq_data__irq, irq_desc, irq_data.irq);
DEFINE_MEMBER_TYPE(irqaction_name, irqaction, name);
DEFINE_MEMBER_TYPE(irqaction_thread, irqaction, thread);
DEFINE_MEMBER_TYPE(device_driver, device, driver);
DEFINE_MEMBER_TYPE(device_bus, device, bus);
DEFINE_MEMBER_TYPE(device_class, device, class);

