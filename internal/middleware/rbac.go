package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/umar5678/go-backend/internal/models"
	"github.com/umar5678/go-backend/internal/utils/response"
)

// Helper to check if role matches any of the allowed roles
func hasRole(userRole string, allowedRoles []string) bool {
	for _, role := range allowedRoles {
		if userRole == role {
			return true
		}
	}
	return false
}

// RequireAdmin ensures user is admin
func RequireAdmin() gin.HandlerFunc {
	return RequireRole(string(models.RoleAdmin))
}

// RequireServiceProvider ensures user is any type of service provider
func RequireServiceProvider() gin.HandlerFunc {
	return RequireRole(
		string(models.RoleServiceProvider),
		string(models.RoleHandyman),
		string(models.RoleDeliveryPerson),
	)
}

// RequireRider ensures user is a rider
func RequireRider() gin.HandlerFunc {
	return RequireRole(string(models.RoleRider))
}

// RequireDriver ensures user is a driver
func RequireDriver() gin.HandlerFunc {
	return RequireRole(string(models.RoleDriver))
}

// RequireRiderOrDriver for ride-related endpoints
func RequireRiderOrDriver() gin.HandlerFunc {
	return RequireRole(
		string(models.RoleRider),
		string(models.RoleDriver),
	)
}

// RequireAdminOrSelf allows access if user is admin OR accessing their own resource
func RequireAdminOrSelf() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("userRole")
		if !exists {
			c.Error(response.UnauthorizedError("Authentication required"))
			c.Abort()
			return
		}

		roleStr, ok := userRole.(string)
		if !ok {
			c.Error(response.UnauthorizedError("Invalid role format"))
			c.Abort()
			return
		}

		// Allow if admin
		if roleStr == string(models.RoleAdmin) {
			c.Next()
			return
		}

		// Allow if accessing own resource
		userID, _ := c.Get("userID")
		resourceUserID := c.Param("id")
		if resourceUserID == "" {
			resourceUserID = c.Param("userId")
		}

		if userID.(string) == resourceUserID {
			c.Next()
			return
		}

		c.Error(response.ForbiddenError("You don't have permission to access this resource"))
		c.Abort()
	}
}

// RequireServiceProviderOrAdmin allows service providers to access their own resources, admins access all
func RequireServiceProviderOrAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("userRole")
		if !exists {
			c.Error(response.UnauthorizedError("Authentication required"))
			c.Abort()
			return
		}

		roleStr, ok := userRole.(string)
		if !ok {
			c.Error(response.UnauthorizedError("Invalid role format"))
			c.Abort()
			return
		}

		// Allow if admin
		if roleStr == string(models.RoleAdmin) {
			c.Next()
			return
		}

		// Allow if any service provider role
		serviceProviderRoles := []string{
			string(models.RoleServiceProvider),
			string(models.RoleHandyman),
			string(models.RoleDeliveryPerson),
		}

		if hasRole(roleStr, serviceProviderRoles) {
			c.Next()
			return
		}

		c.Error(response.ForbiddenError("You don't have permission to access this resource"))
		c.Abort()
	}
}
