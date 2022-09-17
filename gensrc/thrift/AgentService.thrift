// This file is made available under Elastic License 2.0
// This file is based on code available under the Apache license here:
//   https://github.com/apache/incubator-doris/blob/master/gensrc/thrift/AgentService.thrift

// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

namespace cpp starrocks
namespace java com.starrocks.thrift

include "Status.thrift"
include "Types.thrift"
include "InternalService.thrift"
include "PlanNodes.thrift"
include "Descriptors.thrift"
include "Exprs.thrift"

struct TTabletSchema {
    1: required i16 short_key_column_count
    2: required Types.TSchemaHash schema_hash
    3: required Types.TKeysType keys_type
    4: required Types.TStorageType storage_type
    5: required list<Descriptors.TColumn> columns
    6: optional double bloom_filter_fpp
    7: optional list<Descriptors.TOlapTableIndex> indexes
    8: optional bool is_in_memory
    9: optional i64 id;
}

// this enum stands for different storage format in src_backends
// V1 for Segment-V1
// V2 for Segment-V2
enum TStorageFormat {
    DEFAULT,
    V1,
    V2
}

enum TTabletType {
    TABLET_TYPE_DISK = 0,
    TABLET_TYPE_MEMORY = 1,
    TABLET_TYPE_LAKE = 2
}

struct TCreateTabletReq {
    1: required Types.TTabletId tablet_id
    2: required TTabletSchema tablet_schema
    3: optional Types.TVersion version
    5: optional Types.TStorageMedium storage_medium
    6: optional bool in_restore_mode
    // this new tablet should be colocate with base tablet
    7: optional Types.TTabletId base_tablet_id
    8: optional Types.TSchemaHash base_schema_hash
    9: optional i64 table_id
    10: optional i64 partition_id
    // used to find the primary replica among tablet's replicas
    // replica with the largest term is primary replica
    11: optional i64 allocation_term
    // indicate whether this tablet is a compute storage split mode, we call it "eco mode"
    12: optional bool is_eco_mode
    13: optional TStorageFormat storage_format
    14: optional TTabletType tablet_type
    15: optional bool enable_persistent_index
    16: optional Types.TCompressionType compression_type = Types.TCompressionType.LZ4_FRAME
}

struct TDropTabletReq {
    1: required Types.TTabletId tablet_id
    2: optional Types.TSchemaHash schema_hash
    3: optional bool force
}

struct TAlterTabletReq {
    1: required Types.TTabletId base_tablet_id
    2: required Types.TSchemaHash base_schema_hash
    3: required TCreateTabletReq new_tablet_req
}

// This v2 request will replace the old TAlterTabletReq.
// TAlterTabletReq should be deprecated after new alter job process merged.
struct TAlterTabletReqV2 {
    1: required Types.TTabletId base_tablet_id
    2: required Types.TTabletId new_tablet_id
    3: required Types.TSchemaHash base_schema_hash
    4: required Types.TSchemaHash new_schema_hash
    // version of data which this alter task should transform
    5: optional Types.TVersion alter_version
    7: optional list<TAlterMaterializedViewParam> materialized_view_params
    8: optional TTabletType tablet_type
    9: optional i64 txn_id
}

struct TAlterMaterializedViewParam {
    1: required string column_name
    2: optional string origin_column_name
    3: optional Exprs.TExpr mv_expr
}

struct TClusterInfo {
    1: required string user
    2: required string password
}

struct TPushReq {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required Types.TVersion version
    5: required i64 timeout
    6: required Types.TPushType push_type
    7: optional string http_file_path
    8: optional i64 http_file_size
    9: optional list<InternalService.TCondition> delete_conditions
    10: optional bool need_decompress
    // for real time load
    11: optional Types.TTransactionId transaction_id
    12: optional Types.TPartitionId partition_id
    // fe should inform be that this request is running during schema change
    // be should write two files
    13: optional bool is_schema_changing
    // 14 and 15 are used by spark load
    14: optional PlanNodes.TBrokerScanRange broker_scan_range
    15: optional Descriptors.TDescriptorTable desc_tbl

    30: optional bool use_vectorized
    // 31 are used by spark load
    31: optional string timezone

    32: optional TTabletType tablet_type
}

struct TCloneReq {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required list<Types.TBackend> src_backends
    4: optional Types.TStorageMedium storage_medium
    // these are visible version(hash) actually
    5: optional Types.TVersion committed_version
    7: optional i32 task_version
    8: optional i64 src_path_hash
    9: optional i64 dest_path_hash
    10: optional i32 timeout_s

    30: optional bool is_local
}

struct TStorageMediumMigrateReq {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required Types.TStorageMedium storage_medium
}

struct TCancelDeleteDataReq {
    // deprecated
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required Types.TVersion version
}

struct TCheckConsistencyReq {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required Types.TVersion version
}

struct TUploadReq {
    1: required i64 job_id;
    2: required map<string, string> src_dest_map
    3: required Types.TNetworkAddress broker_addr
    4: optional map<string, string> broker_prop
    // If use_broker is set, we will write hdfs thourgh broker
    // If use_broker is not set, we will write through libhdfs/S3 directly
    5: optional bool use_broker = false
    // hdfs_write_buffer_size_kb for writing through lib hdfs directly
    6: optional i32 hdfs_write_buffer_size_kb = 0
    // properties from hdfs-site.xml, core-site.xml and load_properties
    7: optional PlanNodes.THdfsProperties hdfs_properties 
}

struct TDownloadReq {
    1: required i64 job_id
    2: required map<string, string> src_dest_map
    3: required Types.TNetworkAddress broker_addr
    4: optional map<string, string> broker_prop
    // If use_broker is set, we will write hdfs thourgh broker
    // If use_broker is not set, we will write through libhdfs/S3 directly
    5: optional bool use_broker = false
    // hdfs_read_buffer_size_kb for writing through lib hdfs directly
    6: optional i32 hdfs_read_buffer_size_kb = 0
    // properties from hdfs-site.xml, core-site.xml and load_properties
    7: optional PlanNodes.THdfsProperties hdfs_properties 
}

struct TSnapshotRequest {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: optional Types.TVersion version // not used
    5: optional i64 timeout
    6: optional list<Types.TVersion> missing_version
    7: optional bool list_files
    // if all nodes has been upgraded, it can be removed.
    8: optional bool allow_incremental_clone
    9: optional i32 preferred_snapshot_format = Types.TPREFER_SNAPSHOT_REQ_VERSION
    // new format to replace `missing_version`, currently only used for primary tablet snapshot
    // [range1_start, range1_end(inclusive), ... rangeN_start (implicit to INT64_MAX)]
    // size must be 2*N + 1
    10:optional list<Types.TVersion> missing_version_ranges
}

struct TReleaseSnapshotRequest {
    1: required string snapshot_path
}

struct TClearRemoteFileReq {
    1: required string remote_file_path
    2: required map<string, string> remote_source_properties
}

struct TPartitionVersionInfo {
    1: required Types.TPartitionId partition_id
    2: required Types.TVersion version
}

struct TMoveDirReq {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
    3: required string src
    4: required i64 job_id
    5: required bool overwrite
}

enum TAgentServiceVersion {
    V1
}

struct TPublishVersionRequest {
    1: required Types.TTransactionId transaction_id
    2: required list<TPartitionVersionInfo> partition_version_infos
    // strict mode means BE will check tablet missing version
    3: optional bool strict_mode = false // Deprecated
    4: optional i64 commit_timestamp
    5: optional string txn_trace_parent
}

struct TClearAlterTaskRequest {
    1: required Types.TTabletId tablet_id
    2: required Types.TSchemaHash schema_hash
}

struct TClearTransactionTaskRequest {
    1: required Types.TTransactionId transaction_id
    2: required list<Types.TPartitionId> partition_id
}

struct TRecoverTabletReq {
    1: optional Types.TTabletId tablet_id
    2: optional Types.TSchemaHash schema_hash
    3: optional Types.TVersion version
}

enum TTabletMetaType {
    PARTITIONID,
    INMEMORY,
    ENABLE_PERSISTENT_INDEX
}

struct TTabletMetaInfo {
    1: optional Types.TTabletId tablet_id
    2: optional Types.TSchemaHash schema_hash
    3: optional Types.TPartitionId partition_id
    4: optional TTabletMetaType meta_type
    5: optional bool is_in_memory
    6: optional bool enable_persistent_index
}

struct TUpdateTabletMetaInfoReq {
    1: optional list<TTabletMetaInfo> tabletMetaInfos
}

struct TPluginMetaInfo {
    1: required string name
    2: required i32 type
    3: optional string so_name
    4: optional string source
}

struct TAgentTaskRequest {
    1: required TAgentServiceVersion protocol_version
    2: required Types.TTaskType task_type
    3: required i64 signature // every request has unique signature
    4: optional Types.TPriority priority
    5: optional TCreateTabletReq create_tablet_req
    6: optional TDropTabletReq drop_tablet_req
    7: optional TAlterTabletReq alter_tablet_req
    8: optional TCloneReq clone_req
    9: optional TPushReq push_req
    10: optional TCancelDeleteDataReq cancel_delete_data_req //deprecated
    // Deprecated
    11: optional Types.TResourceInfo resource_info
    12: optional TStorageMediumMigrateReq storage_medium_migrate_req
    13: optional TCheckConsistencyReq check_consistency_req
    14: optional TUploadReq upload_req
    15: optional TDownloadReq download_req
    16: optional TSnapshotRequest snapshot_req
    17: optional TReleaseSnapshotRequest release_snapshot_req
    18: optional TClearRemoteFileReq clear_remote_file_req
    19: optional TPublishVersionRequest publish_version_req
    20: optional TClearAlterTaskRequest clear_alter_task_req
    21: optional TClearTransactionTaskRequest clear_transaction_task_req
    22: optional TMoveDirReq move_dir_req
    23: optional TRecoverTabletReq recover_tablet_req
    24: optional TAlterTabletReqV2 alter_tablet_req_v2
    25: optional i64 recv_time // time the task is inserted to queue
    26: optional TUpdateTabletMetaInfoReq update_tablet_meta_info_req
}

struct TAgentResult {
    1: required Status.TStatus status
    2: optional string snapshot_path
    3: optional bool allow_incremental_clone
    // the snapshot that be has done according 
    // to the preferred snapshot version that client requests
    4: optional i32 snapshot_format = 1
}

struct TTopicItem {
    1: required string key
    2: optional i64 int_value
    3: optional double double_value
    4: optional string string_value
}

enum TTopicType {
    RESOURCE
}

struct TTopicUpdate {
    1: required TTopicType type
    2: optional list<TTopicItem> updates
    3: optional list<string> deletes
}

struct TAgentPublishRequest {
    1: required TAgentServiceVersion protocol_version
    2: required list<TTopicUpdate> updates
}

struct TMiniLoadEtlTaskRequest {
    1: required TAgentServiceVersion protocol_version
    2: required InternalService.TExecPlanFragmentParams params
}

struct TMiniLoadEtlStatusRequest {
    1: required TAgentServiceVersion protocol_version
    2: required Types.TUniqueId mini_load_id
}

struct TMiniLoadEtlStatusResult {
    1: required Status.TStatus status
    2: required Types.TEtlState etl_state
    3: optional map<string, i64> file_map
    4: optional map<string, string> counters
    5: optional string tracking_url
    // progress
}

struct TDeleteEtlFilesRequest {
    1: required TAgentServiceVersion protocol_version
    2: required Types.TUniqueId mini_load_id
    3: required string db_name
    4: required string label
}

