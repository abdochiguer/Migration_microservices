package org.springframework.samples.petclinic.vet.web;

import org.springframework.http.ResponseEntity;
import org.springframework.samples.petclinic.vet.model.Vet;
import org.springframework.samples.petclinic.vet.model.Vets;
import org.springframework.samples.petclinic.vet.repository.VetRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class VetController {

    private final VetRepository vetRepository;

    public VetController(VetRepository vetRepository) {
        this.vetRepository = vetRepository;
    }

    /**
     * Endpoint compatible avec le contrat historique du monolithe pour GET /vets
     */
    @GetMapping("/vets")
    public Vets getVets() {
        List<Vet> vetList = this.vetRepository.findAll();
        return new Vets(vetList);
    }

    /**
     * Endpoint REST additionnel pour la consultation par identifiant
     */
    @GetMapping("/vets/{id}")
    public ResponseEntity<Vet> getVetById(@PathVariable Integer id) {
        return this.vetRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
