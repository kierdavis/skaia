module "blk_gp0" {
  source            = "./blk_storage_class"
  name              = "blk-gp0"
  cluster_namespace = local.namespace
  crush_rule        = "skaia_gp0"
  depends_on        = [kubernetes_job.imperative_config]
}

module "blk_media0" {
  source            = "./blk_storage_class"
  name              = "blk-media0"
  cluster_namespace = local.namespace
  crush_rule        = "skaia_media0"
  depends_on        = [kubernetes_job.imperative_config]
}

module "fs_gp0" {
  source            = "./fs_storage_class"
  name              = "fs-gp0"
  cluster_namespace = local.namespace
  fs_name           = kubernetes_manifest.fs.object.metadata.name
  fs_data_pool_name = "data-gp0"
}

module "fs_media0" {
  source            = "./fs_storage_class"
  name              = "fs-media0"
  cluster_namespace = local.namespace
  fs_name           = kubernetes_manifest.fs.object.metadata.name
  fs_data_pool_name = "data-media0"
}
