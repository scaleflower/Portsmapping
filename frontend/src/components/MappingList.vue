<template>
  <el-table-column label="操作" width="200">
    <template #default="{ row }">
      <el-button
        type="primary"
        size="small"
        @click="showDetails(row)"
        :disabled="row.status !== 'running'"
      >
        详情
      </el-button>
      <el-button
        type="danger"
        size="small"
        @click="stopMapping(row.local_port)"
        :disabled="row.status !== 'running'"
      >
        停止
      </el-button>
    </template>
  </el-table-column>
  
  <!-- 添加连接详情对话框 -->
  <ConnectionDetail
    v-model:visible="detailVisible"
    :local-port="selectedPort"
  />
</template>

<script setup>
import { ref } from 'vue'
import ConnectionDetail from './ConnectionDetail.vue'
import { useMappingStore } from '../stores/mapping'
import { ElMessage } from 'element-plus'

const detailVisible = ref(false)
const selectedPort = ref(null)

const showDetails = (row) => {
  selectedPort.value = row.local_port
  detailVisible.value = true
}

// ... 其他代码保持不变 ...
</script> 