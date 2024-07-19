package valheim

import (
	"cue.skaia/kube/system/stash"
)

labels: app: "valheim"

resources: secrets: personal: valheim: metadata: "labels": labels

resources: statefulsets: personal: valheim: {
	metadata: "labels": labels
	spec: {
		selector: matchLabels: labels
		serviceName: "valheim"
		replicas:    0
		template: {
			metadata: "labels": labels
			spec: {
				priorityClassName: "personal-critical"
				affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
					matchExpressions: [{key: "topology.kubernetes.io/zone", operator: "NotIn", values: ["z-adw"]}]
				}]
				containers: [{
					name:  "main"
					image: "cm2network/steamcmd"
					command: ["bash"]
					args: ["-c", """
						set -o errexit -o nounset -o pipefail
						apt-get -y update
						apt-get -y install libatomic1 libc6 libpulse-dev procps sudo
						chown steam:steam /install /gamedata
						cd /home/steam/steamcmd
						sudo -u steam ./steamcmd.sh +force_install_dir /install +login anonymous +app_update 896660 validate +quit
						cd /install
						exec sudo -u steam ./valheim_server.x86_64 -name "$VALHEIM_SERVER_NAME" -port 20002 -world MyWorld -savedir /gamedata -password "$VALHEIM_SERVER_PASSWORD" -crossplay
						"""]
					envFrom: [{secretRef: name: "valheim"}]
					volumeMounts: [
						{name: "install", mountPath:  "/install", readOnly:  false},
						{name: "gamedata", mountPath: "/gamedata", readOnly: false},
					]
					resources: requests: {
						cpu:    "750m"
						memory: "3328Mi"
					}
					securityContext: runAsUser:  0
					securityContext: runAsGroup: 0
				}]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: name: "install"
				spec: {
					accessModes: ["ReadWriteOnce"]
					storageClassName: "ceph-blk-hot0"
					resources: requests: storage: "8Gi"
				}
			},
			{
				metadata: name: "gamedata"
				spec: {
					accessModes: ["ReadWriteOnce"]
					storageClassName: "ceph-blk-hot0"
					resources: requests: storage: "32Gi"
				}
			},
		]
	}
}

resources: poddisruptionbudgets: "personal": "valheim": spec: {
	selector: matchLabels: labels
	maxUnavailable: 0
}

//resources: backupconfigurations: "personal": "valheim": spec: {
//	driver: "Restic"
//	repository: {
//		name:      "personal-valheim-b2"
//		namespace: "stash"
//	}
//	retentionPolicy: {
//		name:        "personal-valheim-b2"
//		keepDaily:   7
//		keepWeekly:  5
//		keepMonthly: 12
//		keepYearly:  1000
//		prune:       true
//	}
//	schedule: "0 4 * * *"
//	target: {
//		ref: {
//			apiVersion: "apps/v1"
//			kind:       "StatefulSet"
//			name:       "valheim"
//		}
//		volumeMounts: [
//			{name: "install", mountPath:  "/install"},
//			{name: "gamedata", mountPath: "/gamedata"},
//		]
//		paths: ["/install", "/gamedata"]
//		exclude: ["lost+found"]
//	}
//	timeOut: "6h"
//}

resources: (stash.repositoryTemplate & {namespace: "personal", name: "valheim"}).resources
