package admin

import (
	"github.com/gin-gonic/gin"
	"github.com/umar5678/go-backend/internal/models"
	"github.com/umar5678/go-backend/internal/utils/response"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// ListUsers - Admin dashboard
func (h *Handler) ListUsers(c *gin.Context) {
	role := c.Query("role")
	status := c.Query("status")
	page := c.DefaultQuery("page", "1")
	limit := c.DefaultQuery("limit", "20")

	result, err := h.service.ListUsers(c.Request.Context(), role, status, page, limit)
	if err != nil {
		c.Error(err)
		return
	}

	response.Success(c, result, "Users retrieved")
}

// ApproveServiceProvider - Admin can approve pending service providers
func (h *Handler) ApproveServiceProvider(c *gin.Context) {
	providerID := c.Param("id")

	if err := h.service.ApproveServiceProvider(c.Request.Context(), providerID); err != nil {
		c.Error(err)
		return
	}

	response.Success(c, nil, "Service provider approved")
}

// SuspendUser - Admin can suspend users
func (h *Handler) SuspendUser(c *gin.Context) {
	userID := c.Param("id")

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.Error(response.BadRequest("Invalid request"))
		return
	}

	if err := h.service.SuspendUser(c.Request.Context(), userID, req.Reason); err != nil {
		c.Error(err)
		return
	}

	response.Success(c, nil, "User suspended")
}

// UpdateUserStatus - Admin can change user status
func (h *Handler) UpdateUserStatus(c *gin.Context) {
	userID := c.Param("id")

	var req struct {
		Status models.UserStatus `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.Error(response.BadRequest("Invalid request"))
		return
	}

	if err := h.service.UpdateUserStatus(c.Request.Context(), userID, req.Status); err != nil {
		c.Error(err)
		return
	}

	response.Success(c, nil, "User status updated")
}

// GetDashboardStats - Admin dashboard statistics
func (h *Handler) GetDashboardStats(c *gin.Context) {
	stats, err := h.service.GetDashboardStats(c.Request.Context())
	if err != nil {
		c.Error(err)
		return
	}

	response.Success(c, stats, "Dashboard stats retrieved")
}
