package main

import (
	"math/rand"
)

type mediaItem struct {
	Id       string `yaml:"id"`
	Redirect string `yaml:"redirect"`
	Text     string `yaml:"text"`
}

func getRandomMediaItem(items []mediaItem) mediaItem {
	return items[rand.Intn(len(items))]
}

func getMediaItemById(items []mediaItem, id string) (mediaItem, bool) {
	for _, item := range items {
		if item.Id == id {
			return item, true
		}
	}
	return mediaItem{}, false
}
