# Python / Django Stack Rules

## Project Structure
- Django apps per domain concept.
- Slim views (logic in services, not views).
- Fat models only for model-specific behavior.
- Service layer for business logic shared across views.

## Django REST Framework
- Serializers for ALL input/output validation.
- ViewSets for CRUD resources, APIView for custom endpoints.
- Permission classes for authorization.
- Pagination on all list endpoints.
- Filtering with django-filter.

## Models
- Explicit field types, no implicit `null=True`.
- Custom managers for complex queries.
- `__str__` on all models.
- Indexes on frequently queried fields.
- Migrations: one migration per logical change.

## OpenAPI Documentation
- Use `drf-spectacular` for OpenAPI 3.1 generation from DRF serializers.
- Add `@extend_schema` decorator on all views/viewsets with summary, description, examples, and error responses.
- Configure `SpectacularAPIView`, `SpectacularSwaggerView`, and `SpectacularRedocView` in URL config.
- Serve Swagger UI at `/api/docs/` and Redoc at `/api/redoc/` in development.
- Every serializer field should have `help_text` for OpenAPI descriptions.
- Use `@extend_schema_serializer(examples=[...])` for request/response examples.
- Run `python manage.py spectacular --validate` in CI to catch spec drift.

## Testing
- `pytest-django` with fixtures.
- `APIClient` for endpoint tests.
- Factory pattern (factory_boy) for test data.
- `@override_settings` for config-dependent tests.
