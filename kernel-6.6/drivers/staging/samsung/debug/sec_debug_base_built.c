// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) 2020 Samsung Electronics Co., Ltd.
 *      http://www.samsung.com
 *
 * Samsung TN debugging code
 *
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_reserved_mem.h>
#include <linux/irq.h>
#include <linux/interrupt.h>
#include <linux/irqdesc.h>
#include <linux/mm.h>
#include <linux/uaccess.h>

#include "sec_debug_internal.h"

static struct sec_debug_gen3 *secdbg_base_va;
static unsigned int sec_debug_gen3_size;
static struct sec_debug_base_param *secdbg_bb_param;

static uint64_t get_sdn_lv1(int type)
{
	if (type < secdbg_base_va->used_offset)
		return (uint64_t)secdbg_base_built_get_ncva(secdbg_base_va->lv1_data[type].addr);

	return 0;
};

/* from PA to NonCachable VA */
static unsigned long sdn_ncva_to_pa_offset;

void *secdbg_base_built_get_ncva(unsigned long pa)
{
	return (void *)(pa + sdn_ncva_to_pa_offset);
}

#if IS_ENABLED(CONFIG_SEC_DEBUG_TASK_IN_STATE_INFO)
void secdbg_base_built_set_task_in_pm_suspend(struct task_struct *task)
{
	struct sec_debug_kernel_data *kernd;

	if (secdbg_base_va) {
		kernd = (struct sec_debug_kernel_data *)get_sdn_lv1(SDN_LV1_KERNEL_DATA);
		kernd->task_in_pm_suspend = (uint64_t)task;
	}
}

void secdbg_base_built_set_task_in_sync_irq(struct task_struct *task,
			unsigned int irq, struct irq_desc *desc)
{
	const char *name = (desc && desc->action) ? desc->action->name : NULL;
	struct sec_debug_kernel_data *kernd;

	if (!secdbg_base_va)
		return;

	kernd = (struct sec_debug_kernel_data *)get_sdn_lv1(SDN_LV1_KERNEL_DATA);
	kernd->sync_irq_task = (uint64_t)task;
	kernd->sync_irq_num = irq;
	kernd->sync_irq_name = (uint64_t)name;
	kernd->sync_irq_desc = (uint64_t)desc;

	if (desc) {
		kernd->sync_irq_threads_active = desc->threads_active.counter;

		if (desc->action && (desc->action->irq == irq) && desc->action->thread)
			kernd->sync_irq_thread = (uint64_t)(desc->action->thread);
		else
			kernd->sync_irq_thread = 0;
	}
}
#endif /* SEC_DEBUG_TASK_IN_STATE_INFO */

#if IS_ENABLED(CONFIG_SEC_DEBUG_PM_DEVICE_INFO)
void secdbg_base_built_set_shutdown_device(const char *fname, const char *dname)
{
	struct sec_debug_kernel_data *kernd;

	if (secdbg_base_va) {
		kernd = (struct sec_debug_kernel_data *)get_sdn_lv1(SDN_LV1_KERNEL_DATA);
		kernd->sdi.shutdown_func = (uint64_t)fname;
		kernd->sdi.shutdown_device = (uint64_t)dname;
	}
}

void secdbg_base_built_set_suspend_device(const char *fname, const char *dname)
{
	struct sec_debug_kernel_data *kernd;

	if (secdbg_base_va) {
		kernd = (struct sec_debug_kernel_data *)get_sdn_lv1(SDN_LV1_KERNEL_DATA);
		kernd->sdi.suspend_func = (uint64_t)fname;
		kernd->sdi.suspend_device = (uint64_t)dname;
	}
}
#endif /* SEC_DEBUG_PM_DEVICE_INFO */

void *secdbg_base_built_get_debug_base(int type)
{
	if (secdbg_base_va) {
		if (type == SDN_MAP_AUTO_COMMENT)
			return (void *)get_sdn_lv1(SDN_LV1_AUTO_COMMENT);
	}

	pr_crit("%s: return NULL\n", __func__);

	return NULL;
}

unsigned long secdbg_base_built_get_buf_base(int type)
{
	struct secdbg_logbuf_list *p;

	if (secdbg_base_va) {
		p = (struct secdbg_logbuf_list *)get_sdn_lv1(SDN_LV1_LOGBUF_MAP);

		pr_debug("%s: return %p (%llx)\n", __func__,
			secdbg_base_va, p->data[type].base);
		return p->data[type].base;
	}

	pr_crit("%s: return 0\n", __func__);

	return 0;
}

unsigned long secdbg_base_built_get_buf_size(int type)
{
	struct secdbg_logbuf_list *p;

	if (secdbg_base_va) {
		p = (struct secdbg_logbuf_list *)get_sdn_lv1(SDN_LV1_LOGBUF_MAP);

		pr_debug("%s: return %p (%llx)\n", __func__,
			secdbg_base_va, p->data[type].size);
		return p->data[type].size;
	}

	pr_crit("%s: return 0\n", __func__);

	return 0;
}

static void secdbg_base_built_wait_for_init(struct sec_debug_base_param *param)
{
	/*
	 * We must ensure sdn is cleared completely hear.
	 * Pairs with the smp_store_release() in
	 * secdbg_base_set_sdn_ready().
	 */
	smp_cond_load_acquire(&param->init_sdn_done, VAL);
}

static int secdbg_base_built_probe(struct platform_device *pdev)
{
	struct reserved_mem *rmem;
	struct device_node *rmem_np;

	rmem_np = of_parse_phandle(pdev->dev.of_node, "memory-region", 0);
	if (!rmem_np) {
		pr_crit("%s: no such memory-region\n", __func__);
		return -ENODEV;
	}

	rmem = of_reserved_mem_lookup(rmem_np);
	if (!rmem) {
		pr_crit("%s: no such reserved mem of node name %s\n",
				__func__, pdev->dev.of_node->name);
		return -ENODEV;
	}

	if (!rmem->base || !rmem->size || !rmem->priv) {
		pr_debug("%s: not ready ...\n", __func__);
		return -EPROBE_DEFER;
	}

	secdbg_bb_param = (struct sec_debug_base_param *)rmem->priv;
	secdbg_base_built_wait_for_init(secdbg_bb_param);

	secdbg_base_va = (struct sec_debug_gen3 *)(secdbg_bb_param->sdn_vaddr);
	sec_debug_gen3_size = (unsigned int)(rmem->size);

	sdn_ncva_to_pa_offset =  (unsigned long)secdbg_base_va - (unsigned long)rmem->base;
	pr_debug("%s: offset from va: %lx\n", __func__, sdn_ncva_to_pa_offset);

	pr_debug("%s: va: %llx ++ %x\n", __func__, (uint64_t)(rmem->priv),
					(unsigned int)(rmem->size));

	secdbg_comm_auto_comment_init();

#if IS_ENABLED(CONFIG_SEC_DEBUG_MEMTAB)
	secdbg_base_built_set_memtab_info((struct sec_debug_memtab *)get_sdn_lv1(SDN_LV1_MEMTAB));
#endif

	pr_info("sec_debug_base_built probed. size=0x%x\n", sec_debug_gen3_size);

	return 0;
}

static const struct of_device_id sec_debug_built_of_match[] = {
	{ .compatible	= "samsung,sec_debug_built" },
	{},
};
MODULE_DEVICE_TABLE(of, sec_debug_built_of_match);

static struct platform_driver sec_debug_built_driver = {
	.probe = secdbg_base_built_probe,
	.driver  = {
		.name  = "sec_debug_base_built",
		.of_match_table = of_match_ptr(sec_debug_built_of_match),
	},
};

static __init int secdbg_base_built_init(void)
{
	return platform_driver_register(&sec_debug_built_driver);
}
late_initcall_sync(secdbg_base_built_init);

static void __exit secdbg_base_built_exit(void)
{
	platform_driver_unregister(&sec_debug_built_driver);
}
module_exit(secdbg_base_built_exit);

MODULE_DESCRIPTION("Samsung Debug base builtin driver");
MODULE_LICENSE("GPL");
