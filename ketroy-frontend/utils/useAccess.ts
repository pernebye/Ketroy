export function useAccess() {
    const storedRoles = localStorage.getItem('roles')
    const roles = ref(storedRoles ? JSON.parse(storedRoles) : [])

    const hasRole = (role: string) => {
        return roles.value.some((r: any) => r.name === role)
    }

    const hasAnyRole = (requiredRoles: string[]) => {
        return requiredRoles.some(role => hasRole(role))
    }

    return {
        hasRole,
        hasAnyRole,
    }
}
