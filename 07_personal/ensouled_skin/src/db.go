package main

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"os"
	"time"
)

type assignment struct {
	ID                uint `gorm:"primarykey"`
	ClientAddr        string
	ClientFingerprint string
	MediaId           string
	CreatedAt         time.Time
	UpdatedAt         time.Time
	ExpiresAt         time.Time
}

func initDB() (*gorm.DB, error) {
	dsn := os.Getenv("POSTGRES_DSN")
	if dsn == "" {
		return nil, fmt.Errorf("POSTGRES_DSN environment variable not set")
	}
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	err = db.AutoMigrate(assignment{})
	if err != nil {
		return nil, fmt.Errorf("failed to execute migrations: %w", err)
	}
	return db, nil
}

func getAssignment(db *gorm.DB, media []mediaItem, clientAddr, clientFingerprint string) (mediaItem, error) {
	var assignedItem mediaItem
	err := db.Transaction(func(tx *gorm.DB) error {
		var asgn assignment
		err := tx.Where(assignment{ClientAddr: clientAddr, ClientFingerprint: clientFingerprint}).Limit(1).Find(&asgn).Error
		if err != nil {
			return fmt.Errorf("failed to query for a existing assignment: %w", err)
		}
		// asgn.MediaId may be "" if there was no matching record in the table.
		// It could also be invalid if the media list has been altered since the record was created.
		if item, ok := getMediaItemById(media, asgn.MediaId); ok {
			assignedItem = item
		} else {
			assignedItem = getRandomMediaItem(media)
		}
		asgn.ClientAddr = clientAddr
		asgn.ClientFingerprint = clientFingerprint
		asgn.MediaId = assignedItem.Id
		asgn.ExpiresAt = time.Now().Add(assignmentTTL)
		err = tx.Save(&asgn).Error
		if err != nil {
			return fmt.Errorf("failed to create/update assignment: %w", err)
		}
		return nil
	})
	return assignedItem, err
}
