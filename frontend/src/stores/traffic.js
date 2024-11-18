import { defineStore } from 'pinia'
import { mappingApi } from '../api/mapping'

export const useTrafficStore = defineStore('traffic', {
  state: () => ({
    trafficData: {},
    updateInterval: null
  }),

  actions: {
    startMonitoring(localPort) {
      if (!this.trafficData[localPort]) {
        this.trafficData[localPort] = {
          history: [],
          current: null
        }
      }

      // 每秒更新一次数据
      this.updateInterval = setInterval(async () => {
        try {
          const response = await mappingApi.getMappingStatus(localPort)
          const traffic = response.data.traffic
          
          if (traffic) {
            this.trafficData[localPort].current = traffic
            this.trafficData[localPort].history.push({
              timestamp: new Date(),
              ...traffic
            })

            // 只保留最近30分钟的数据
            if (this.trafficData[localPort].history.length > 1800) {
              this.trafficData[localPort].history.shift()
            }
          }
        } catch (error) {
          console.error('获取流量数据失败:', error)
        }
      }, 1000)
    },

    stopMonitoring() {
      if (this.updateInterval) {
        clearInterval(this.updateInterval)
        this.updateInterval = null
      }
    }
  }
}) 