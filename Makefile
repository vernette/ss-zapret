DOCKER_IMAGE = ss-zapret
CURRENT_TAG = $(shell grep ZAPRET_TAG .env 2>/dev/null | cut -d '=' -f2)
LATEST_TAG = $(shell wget -qO- https://api.github.com/repos/bol-van/zapret/releases/latest | grep -e "tag_name" | cut -d '"' -f 4)
DOCKER_COMPOSE_CMD = $(shell which docker-compose 2>/dev/null || echo "docker compose")

# Всегда используем текущий тег, если он есть, иначе последний
TAG = $(if $(CURRENT_TAG),$(CURRENT_TAG),$(LATEST_TAG))

build:
	@echo "Собираем образ с тегом ${TAG}..."
	@if grep -q "^ZAPRET_TAG=" .env; then \
		sed -i "s/^ZAPRET_TAG=.*/ZAPRET_TAG=${TAG}/" .env; \
	else \
		echo "ZAPRET_TAG=${TAG}" >> .env; \
	fi
	$(DOCKER_COMPOSE_CMD) build --build-arg ZAPRET_TAG=${TAG}

update:
	@if [ "${LATEST_TAG}" != "${TAG}" ]; then \
		echo "Обновляем до версии ${LATEST_TAG}..."; \
		sed -i "s/^ZAPRET_TAG=.*/ZAPRET_TAG=${LATEST_TAG}/" .env; \
		$(MAKE) build; \
	else \
		echo "У вас уже установлена последняя версия"; \
	fi

up:
	@echo "Запускаем контейнер с тегом ${TAG}..."
	$(DOCKER_COMPOSE_CMD) up -d

down:
	@echo "Останавливаем контейнер с тегом ${TAG}..."
	$(DOCKER_COMPOSE_CMD) down

logs:
	@echo "Просмотр логов контейнера с тегом ${TAG}..."
	$(DOCKER_COMPOSE_CMD) logs -f

clean:
	@echo "Удаляем образ Docker с тегом ${TAG}..."
	docker rmi $(DOCKER_IMAGE):$(TAG) || echo "Образ не найден."
