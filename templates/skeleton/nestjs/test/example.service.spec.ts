import { InMemoryExampleRepository } from '../src/example/example.repository';
import {
  DuplicateExampleNameError,
  ExampleNotFoundError,
  ExampleService,
} from '../src/example/example.service';

/** Unit tests. Naming: Subject_Scenario_ExpectedResult (AGENTS.md A4). */
describe('ExampleService', () => {
  let service: ExampleService;

  beforeEach(() => {
    service = new ExampleService(new InMemoryExampleRepository());
  });

  it('create_WithNewName_ReturnsExample', () => {
    const created = service.create('first');

    expect(created.name).toBe('first');
    expect(created.id).toBeTruthy();
  });

  it('create_WithDuplicateName_ThrowsConflict', () => {
    service.create('taken');

    expect(() => service.create('taken')).toThrow(DuplicateExampleNameError);
  });

  it('get_WithKnownId_ReturnsExample', () => {
    const created = service.create('known');

    expect(service.get(created.id).id).toBe(created.id);
  });

  it('get_WithUnknownId_ThrowsNotFound', () => {
    expect(() => service.get('does-not-exist')).toThrow(ExampleNotFoundError);
  });

  it('create_TwiceWithDifferentNames_ReturnsDistinctIds', () => {
    expect(service.create('one').id).not.toBe(service.create('two').id);
  });
});
