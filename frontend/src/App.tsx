import { FormEvent, useMemo, useState } from 'react'
import { askQuestion } from './api'
import type { AskResponse, ChartPoint, ChartSpec } from './types'

const SAMPLE_QUESTIONS = [
  'How many orders were placed in the last 7 days?',
  'Which products sold the most last month?',
  'Show a table of revenue by city.',
  'Who are my repeat customers?',
  'What is the AOV trend this month?',
  'Plot a graph of order volume over the past 4 weeks.',
]

export default function App() {
  const [question, setQuestion] = useState(SAMPLE_QUESTIONS[0])
  const [response, setResponse] = useState<AskResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const hasChart = Boolean(response?.chart?.series?.length)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const data = await askQuestion(question)
      setResponse(data)
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected request failure')
      setResponse(null)
    } finally {
      setLoading(false)
    }
  }

  const chart = useMemo(() => response?.chart ?? null, [response])

  return (
    <main className="shell">
      <section className="hero">
        <div className="hero__copy">
          <p className="eyebrow">Shopify analytics cockpit</p>
          <h1>Ask a question, get the answer, and inspect the data behind it.</h1>
        </div>
      </section>

      <section className="workspace">
        <form className="composer" onSubmit={handleSubmit}>
          <label htmlFor="question" className="label">
            Ask Shopify
          </label>
          <textarea
            id="question"
            value={question}
            onChange={(event) => setQuestion(event.target.value)}
            rows={4}
            placeholder="Type a business question about orders, products, customers, or revenue..."
          />

          <div className="quick-asks">
            {SAMPLE_QUESTIONS.map((sample) => (
              <button key={sample} type="button" className="quick-ask" onClick={() => setQuestion(sample)}>
                {sample}
              </button>
            ))}
          </div>

          <button className="submit" type="submit" disabled={loading}>
            {loading ? 'Analyzing…' : 'Run analysis'}
          </button>
        </form>

        <section className="results">
          <div className="results__header">
            <h2>Result</h2>
            <p>{loading ? 'Fetching and analyzing Shopify data.' : 'Latest response from the backend agent.'}</p>
          </div>

          {error ? <div className="alert alert--error">{error}</div> : null}

          {!error && !response && !loading ? (
            <div className="empty-state">
              Run one of the sample prompts to verify the full backend-to-frontend flow.
            </div>
          ) : null}

          {response ? (
            <>
              <article className="answer-card">
                <h3>Answer</h3>
                <p>{response.answer}</p>
                {response.warnings.length > 0 ? (
                  <ul className="warnings">
                    {response.warnings.map((warning) => (
                      <li key={warning}>{warning}</li>
                    ))}
                  </ul>
                ) : null}
              </article>

              {response.table.length > 0 ? <DataTable rows={response.table} /> : null}
              {hasChart && chart ? <ChartCard chart={chart} /> : null}
            </>
          ) : null}
        </section>
      </section>
    </main>
  )
}

function DataTable({ rows }: { rows: Record<string, unknown>[] }) {
  const columns = useMemo(() => {
    const keys = new Set<string>()
    rows.forEach((row) => Object.keys(row).forEach((key) => keys.add(key)))
    return Array.from(keys)
  }, [rows])

  return (
    <article className="table-card">
      <div className="table-card__head">
        <h3>Table</h3>
        <span>{rows.length} rows</span>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column}>{column}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, rowIndex) => (
              <tr key={rowIndex}>
                {columns.map((column) => (
                  <td key={column}>{formatCell(row[column])}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </article>
  )
}

function ChartCard({ chart }: { chart: ChartSpec }) {
  const series = chart.series[0]
  const points = series?.points ?? []
  if (points.length === 0) {
    return null
  }

  const values = points.map((point) => point.y)
  const maxValue = Math.max(...values, 1)
  const minValue = Math.min(...values, 0)
  const width = 840
  const height = 280
  const paddingX = 40
  const paddingY = 28
  const innerWidth = width - paddingX * 2
  const innerHeight = height - paddingY * 2
  const stepX = points.length > 1 ? innerWidth / (points.length - 1) : innerWidth
  const scaleY = (value: number) => {
    if (maxValue === minValue) {
      return height / 2
    }
    return paddingY + innerHeight - ((value - minValue) / (maxValue - minValue)) * innerHeight
  }

  const path = points
    .map((point, index) => {
      const x = paddingX + stepX * index
      const y = scaleY(point.y)
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`
    })
    .join(' ')

  return (
    <article className="chart-card">
      <div className="table-card__head">
        <h3>{chart.title}</h3>
        <span>{chart.type}</span>
      </div>

      <svg viewBox={`0 0 ${width} ${height}`} className="chart" role="img" aria-label={chart.title}>
        <line x1={paddingX} y1={height - paddingY} x2={width - paddingX} y2={height - paddingY} className="axis" />
        <line x1={paddingX} y1={paddingY} x2={paddingX} y2={height - paddingY} className="axis" />

        {chart.type === 'bar'
          ? points.map((point, index) => {
              const barWidth = innerWidth / points.length - 12
              const x = paddingX + index * (innerWidth / points.length) + 6
              const barHeight = ((point.y - minValue) / (maxValue - minValue || 1)) * innerHeight
              const y = height - paddingY - barHeight

              return (
                <g key={`${point.x}-${index}`}>
                  <rect x={x} y={y} width={barWidth} height={barHeight} rx={8} className="bar" />
                  <text x={x + barWidth / 2} y={height - 10} textAnchor="middle" className="tick-label">
                    {point.x}
                  </text>
                </g>
              )
            })
          : null}

        {chart.type === 'line' ? <path d={path} className="line" /> : null}
        {chart.type === 'line'
          ? points.map((point, index) => {
              const x = paddingX + stepX * index
              const y = scaleY(point.y)
              return <circle key={`${point.x}-${index}`} cx={x} cy={y} r={4.5} className="dot" />
            })
          : null}

        {chart.type === 'line'
          ? points.map((point, index) => {
              const x = paddingX + stepX * index
              const y = height - 10
              return (
                <text key={`${point.x}-${index}`} x={x} y={y} textAnchor="middle" className="tick-label">
                  {point.x}
                </text>
              )
            })
          : null}
      </svg>

      <div className="axis-labels">
        <span>{chart.x_label}</span>
        <span>{chart.y_label}</span>
      </div>
    </article>
  )
}

function formatCell(value: unknown) {
  if (value === null || value === undefined) {
    return '—'
  }

  if (typeof value === 'object') {
    return JSON.stringify(value)
  }

  return String(value)
}
