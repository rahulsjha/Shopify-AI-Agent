import type { AskResponse } from './types'

const DEFAULT_BASE_URL = 'http://localhost:8000'

export async function askQuestion(question: string): Promise<AskResponse> {
  const baseUrl = import.meta.env.VITE_API_BASE_URL ?? DEFAULT_BASE_URL
  const response = await fetch(`${baseUrl}/api/ask`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ question }),
  })

  if (!response.ok) {
    const errorBody = await safeReadJson(response)
    const message = errorBody?.detail ?? `Request failed with status ${response.status}`
    throw new Error(message)
  }

  return response.json() as Promise<AskResponse>
}

async function safeReadJson(response: Response): Promise<{ detail?: string } | null> {
  try {
    return (await response.json()) as { detail?: string }
  } catch {
    return null
  }
}
