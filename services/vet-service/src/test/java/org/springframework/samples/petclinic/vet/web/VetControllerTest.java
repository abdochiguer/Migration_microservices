package org.springframework.samples.petclinic.vet.web;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.samples.petclinic.vet.model.Specialty;
import org.springframework.samples.petclinic.vet.model.Vet;
import org.springframework.samples.petclinic.vet.repository.VetRepository;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(VetController.class)
class VetControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private VetRepository vetRepository;

    private Vet james;
    private Vet helen;

    @BeforeEach
    void setUp() {
        james = new Vet(1, "James", "Carter");

        helen = new Vet(2, "Helen", "Leary");
        Specialty radiology = new Specialty(1, "radiology");
        helen.addSpecialty(radiology);
    }

    @Test
    void shouldReturnVetListMatchingLegacyContract() throws Exception {
        given(vetRepository.findAll()).willReturn(List.of(james, helen));

        mockMvc.perform(get("/vets").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.vetList[0].id").value(1))
                .andExpect(jsonPath("$.vetList[0].firstName").value("James"))
                .andExpect(jsonPath("$.vetList[0].lastName").value("Carter"))
                .andExpect(jsonPath("$.vetList[1].id").value(2))
                .andExpect(jsonPath("$.vetList[1].firstName").value("Helen"))
                .andExpect(jsonPath("$.vetList[1].specialties[0].name").value("radiology"))
                .andExpect(jsonPath("$.vetList[1].nrOfSpecialties").value(1));
    }

    @Test
    void shouldReturnVetByIdWhenFound() throws Exception {
        given(vetRepository.findById(1)).willReturn(Optional.of(james));

        mockMvc.perform(get("/vets/1").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.firstName").value("James"));
    }

    @Test
    void shouldReturn404WhenVetNotFound() throws Exception {
        given(vetRepository.findById(999)).willReturn(Optional.empty());

        mockMvc.perform(get("/vets/999").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }
}
