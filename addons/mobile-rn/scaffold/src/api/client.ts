/**
 * Typed fetch helpers for talking to the backend.
 *
 * Convention: never call fetch() directly from screens. Always go through
 * a hook or function in this file. Keeps API contract surface inspectable.
 */

const API_BASE =
  process.env.EXPO_PUBLIC_API_BASE ?? "http://localhost:8000";

export class ApiError extends Error {
  constructor(
    public status: number,
    public body: unknown,
    message: string
  ) {
    super(message);
  }
}

async function request<T>(
  path: string,
  init: RequestInit = {}
): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init.headers,
    },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new ApiError(res.status, body, `${res.status} ${res.statusText}`);
  }

  return res.json() as Promise<T>;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "POST", body: JSON.stringify(body) }),
  put: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "PUT", body: JSON.stringify(body) }),
  del: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};

// Example typed endpoint — replace with generated clients from openapi-clients addon.
export interface HealthResponse {
  status: string;
  version: string;
  build: string;
}

export const getHealth = () => api.get<HealthResponse>("/api/health");
