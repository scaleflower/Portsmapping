<template>
  <el-dialog
    v-model="visible"
    :title="`端口 ${localPort} 连接详情`"
    width="70%"
  >
    <el-tabs>
      <!-- 基本信息 -->
      <el-tab-pane label="基本信息">
        <el-descriptions border>
          <el-descriptions-item label="本地端口">{{ details.local_port }}</el-descriptions-item>
          <el-descriptions-item label="远程主机">{{ details.remote_host }}</el-descriptions-item>
          <el-descriptions-item label="远程端口">{{ details.remote_port }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="details.status === 'running' ? 'success' : 'danger'">
              {{ details.status }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="启动时间">{{ formatTime(details.start_time) }}</el-descriptions-item>
          <el-descriptions-item label="运行时长">{{ calculateUptime(details.start_time) }}</el-descriptions-item>
        </el-descriptions>
      </el-tab-pane>

      <!-- 流量统计 -->
      <el-tab-pane label="流量统计">
        <div class="traffic-stats">
          <el-row :gutter="20">
            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>当前连接数</template>
                <div class="stats-value">{{ details.traffic?.connections || 0 }}</div>
              </el-card>
            </el-col>
            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>总上传流量</template>
                <div class="stats-value">{{ formatBytes(details.traffic?.bytes_sent || 0) }}</div>
              </el-card>
            </el-col>
            <el-col :span="8">
              <el-card shadow="hover">
                <template #header>总下载流量</template>
                <div class="stats-value">{{ formatBytes(details.traffic?.bytes_recv || 0) }}</div>
              </el-card>
            </el-col>
          </el-row>
          <div class="traffic-chart" ref="chartRef"></div>
        </div>
      </el-tab-pane>

      <!-- 实时日志 -->
      <el-tab-pane label="实时日志">
        <div class="log-container">
          <el-timeline>
            <el-timeline-item
              v-for="(log, index) in logs"
              :key="index"
              :timestamp="log.timestamp"
              :type="getLogType(log.level)"
            >
              {{ log.message }}
            </el-timeline-item>
          </el-timeline>
        </div>
      </el-tab-pane>
    </el-tabs>
  </el-dialog>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'
import { mappingApi } from '../api/mapping'

const props = defineProps({
  visible: Boolean,
  localPort: Number
})

const emit = defineEmits(['update:visible'])

const details = ref({})
const logs = ref([])
const chartRef = ref(null)
let chart = null
let updateTimer = null

// 格式化字节数
const formatBytes = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 格式化时间
const formatTime = (time) => {
  return new Date(time).toLocaleString()
}

// 计算运行时长
const calculateUptime = (startTime) => {
  const start = new Date(startTime)
  const now = new Date()
  const diff = Math.floor((now - start) / 1000)
  
  const days = Math.floor(diff / 86400)
  const hours = Math.floor((diff % 86400) / 3600)
  const minutes = Math.floor((diff % 3600) / 60)
  
  return `${days}天 ${hours}小时 ${minutes}分钟`
}

// 初始化图表
const initChart = () => {
  if (chartRef.value) {
    chart = echarts.init(chartRef.value)
    const option = {
      title: {
        text: '实时流量监控'
      },
      tooltip: {
        trigger: 'axis'
      },
      legend: {
        data: ['上传速率', '下载速率']
      },
      xAxis: {
        type: 'time',
        splitLine: {
          show: false
        }
      },
      yAxis: {
        type: 'value',
        name: 'KB/s'
      },
      series: [
        {
          name: '上传速率',
          type: 'line',
          smooth: true,
          data: []
        },
        {
          name: '下载速率',
          type: 'line',
          smooth: true,
          data: []
        }
      ]
    }
    chart.setOption(option)
  }
}

// 更新数据
const updateData = async () => {
  try {
    const response = await mappingApi.getMappingStatus(props.localPort)
    details.value = response.data
    
    // 更新图表数据
    if (chart && response.data.traffic) {
      const now = new Date()
      const uploadSpeed = response.data.traffic.bytes_sent / 1024 // KB/s
      const downloadSpeed = response.data.traffic.bytes_recv / 1024 // KB/s
      
      chart.setOption({
        series: [
          {
            data: [...chart.getOption().series[0].data, [now, uploadSpeed]]
          },
          {
            data: [...chart.getOption().series[1].data, [now, downloadSpeed]]
          }
        ]
      })
    }
  } catch (error) {
    console.error('获取映射详情失败:', error)
  }
}

// 获取日志类型
const getLogType = (level) => {
  const types = {
    'ERROR': 'danger',
    'WARNING': 'warning',
    'INFO': 'primary'
  }
  return types[level] || 'info'
}

// 监听对话框显示状态
watch(() => props.visible, (newVal) => {
  if (newVal) {
    updateData()
    updateTimer = setInterval(updateData, 2000)
  } else {
    clearInterval(updateTimer)
  }
})

onMounted(() => {
  initChart()
})

onUnmounted(() => {
  clearInterval(updateTimer)
  if (chart) {
    chart.dispose()
  }
})
</script>

<style scoped>
.traffic-stats {
  margin-top: 20px;
}

.stats-value {
  font-size: 24px;
  font-weight: bold;
  text-align: center;
  color: #409EFF;
}

.traffic-chart {
  height: 400px;
  margin-top: 20px;
}

.log-container {
  height: 400px;
  overflow-y: auto;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 4px;
}
</style> 