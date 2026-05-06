export type ChartPoint = {
  x: string
  y: number
}

export type ChartSeries = {
  name: string
  points: ChartPoint[]
}

export type ChartSpec = {
  type: 'line' | 'bar'
  title: string
  x_label: string
  y_label: string
  series: ChartSeries[]
}

export type AskResponse = {
  answer: string
  table: Record<string, unknown>[]
  chart: ChartSpec | null
  warnings: string[]
  raw_output?: string | null
}
